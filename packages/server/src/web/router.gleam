import gleam/dict.{type Dict}
import gleam/dynamic
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import store/store_data_access as data_access
import store/store_validation
import web/server.{type Request, type Response}
import web/static

/// Router handler function
pub fn make_handler() -> fn(Request) -> Response {
  fn(request: Request) { route(request) }
}

/// Main routing logic
fn route(request: Request) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "PUT", path -> route_put(path, request)
    "GET", path -> route_get(path)
    _, _ -> not_found()
  }
}

/// Route PUT requests for stores
fn route_put(path: String, request: Request) -> Response {
  case string.starts_with(path, "/api/stores/") {
    True -> update_store_handler(path, request)
    False -> not_found()
  }
}

/// Handle GET requests
fn route_get(path: String) -> Response {
  case string.starts_with(path, "/static/") {
    True -> static.serve(path)
    False -> not_found()
  }
}

/// Health check handler
fn health_handler() -> Response {
  server.json_response(
    200,
    json.object([#("status", json.string("ok"))])
    |> json.to_string,
  )
}

/// Not found response
fn not_found() -> server.Response {
  server.json_response(
    404,
    json.object([#("error", json.string("Not found"))])
    |> json.to_string,
  )
}

/// Empty 404 response for store not found
fn store_not_found_empty() -> server.Response {
  server.Response(status: 404, headers: dict.new(), body: "")
}

/// Parse store ID from path like "/api/stores/store-123"
fn parse_store_id(path: String) -> Option(String) {
  let parts = string.split(path, "/")
  case parts {
    ["", "api", "stores", id] -> Some(id)
    _ -> None
  }
}

/// Decode JSON payload for store update - returns Dict with Dynamic values
fn decode_update_payload(body: String) -> Result(Dict(String, dynamic.Dynamic), String) {
  let decoder = decode.dict(decode.string, decode.dynamic)
  case json.parse(body, decoder) {
    Ok(dict) -> Ok(dict)
    Error(_) -> Error("Invalid JSON payload")
  }
}

/// Get optional string field from decoded payload
/// Returns Some(value) if present and valid, None if missing or null
fn get_optional_string_field(
  dict: Dict(String, dynamic.Dynamic),
  field: String,
) -> Option(String) {
  case dict.get(dict, field) {
    Ok(dyn) -> {
      case decode.run(dyn, decode.string) {
        Ok(value) -> Some(value)
        Error(_) -> None
      }
    }
    Error(_) -> None
  }
}

/// Handler for PUT /api/stores/:id - update store
fn update_store_handler(path: String, request: Request) -> Response {
  let store_id_opt = parse_store_id(path)

  case store_id_opt {
    None -> not_found()
    Some(store_id) -> {
      case decode_update_payload(request.body) {
        Error(_) -> {
          server.json_response(
            422,
            json.object([#("errors", json.array([json.string("Invalid JSON")], of: fn(x) { x }))])
            |> json.to_string,
          )
        }
        Ok(payload_dict) -> {
          let state = data_access.new_state()
          process_store_update(state, store_id, payload_dict)
        }
      }
    }
  }
}

/// Convert error pairs to JSON objects
fn error_to_json(pair: #(String, String)) -> json.Json {
  json.object([
    #("field", json.string(pair.0)),
    #("message", json.string(pair.1)),
  ])
}

/// Process store update with given state
fn process_store_update(
  state: data_access.StoreState,
  store_id: String,
  payload_dict: Dict(String, dynamic.Dynamic),
) -> Response {
  case data_access.get_by_id(state, store_id) {
    Error(_) -> store_not_found_empty()
    Ok(existing_store) -> {
      let name_opt = get_optional_string_field(payload_dict, "name")
      let address_opt = get_optional_string_field(payload_dict, "address")
      let city_opt = get_optional_string_field(payload_dict, "city")
      let phone_opt = get_optional_string_field(payload_dict, "phone")

      let validation_name = case name_opt {
        Some(name) -> name
        None -> existing_store.name
      }

      let validation_input = store_validation.StoreValidationInput(
        name: validation_name,
        address: case address_opt {
          Some(addr) -> Some(addr)
          None -> existing_store.address
        },
        phone: case phone_opt {
          Some(phone) -> Some(phone)
          None -> existing_store.phone
        },
      )

      case store_validation.validate(validation_input) {
        store_validation.Invalid(errors) -> {
          let error_pairs = store_validation.errors_to_pairs(errors)
          let error_objects = list.map(error_pairs, error_to_json)
          server.json_response(
            422,
            json.object([#("errors", json.array(error_objects, of: fn(x) { x }))])
            |> json.to_string,
          )
        }
        store_validation.Valid -> {
          let update_input = data_access.UpdateStoreInput(
            name: name_opt,
            address: address_opt,
            city: city_opt,
            phone: phone_opt,
          )

          let #(_, update_result) = data_access.update(state, store_id, update_input)

          case update_result {
            Error(_) -> store_not_found_empty()
            Ok(updated_store) -> {
              let response_obj = json.object([
                #("id", json.string(updated_store.id)),
                #("name", json.string(updated_store.name)),
                #("address", case updated_store.address {
                  Some(addr) -> json.string(addr)
                  None -> json.null()
                }),
                #("city", case updated_store.city {
                  Some(city) -> json.string(city)
                  None -> json.null()
                }),
                #("phone", case updated_store.phone {
                  Some(phone) -> json.string(phone)
                  None -> json.null()
                }),
                #("updated_at", json.string(updated_store.updated_at)),
              ])
              server.json_response(200, json.to_string(response_obj))
            }
          }
        }
      }
    }
  }
}

/// Handler that takes explicit state for testing
pub fn handle_request(request: Request, state: data_access.StoreState) -> Response {
  case request.method, request.path {
    "PUT", path -> {
      case string.starts_with(path, "/api/stores/") {
        True -> {
          let store_id_opt = parse_store_id(path)
          case store_id_opt {
            None -> not_found()
            Some(store_id) -> {
              case decode_update_payload(request.body) {
                Error(_) -> {
                  server.json_response(
                    422,
                    json.object([#("errors", json.array([json.string("Invalid JSON")], of: fn(x) { x }))])
                    |> json.to_string,
                  )
                }
                Ok(payload_dict) -> {
                  process_store_update_with_state(state, store_id, payload_dict)
                }
              }
            }
          }
        }
        False -> not_found()
      }
    }
    _, _ -> route(request)
  }
}

/// Process store update with explicit state for testing
fn process_store_update_with_state(
  state: data_access.StoreState,
  store_id: String,
  payload_dict: Dict(String, dynamic.Dynamic),
) -> Response {
  case data_access.get_by_id(state, store_id) {
    Error(_) -> store_not_found_empty()
    Ok(existing_store) -> {
      let name_opt = get_optional_string_field(payload_dict, "name")
      let address_opt = get_optional_string_field(payload_dict, "address")
      let city_opt = get_optional_string_field(payload_dict, "city")
      let phone_opt = get_optional_string_field(payload_dict, "phone")

      let validation_name = case name_opt {
        Some(name) -> name
        None -> existing_store.name
      }

      let validation_input = store_validation.StoreValidationInput(
        name: validation_name,
        address: case address_opt {
          Some(addr) -> Some(addr)
          None -> existing_store.address
        },
        phone: case phone_opt {
          Some(phone) -> Some(phone)
          None -> existing_store.phone
        },
      )

      case store_validation.validate(validation_input) {
        store_validation.Invalid(errors) -> {
          let error_pairs = store_validation.errors_to_pairs(errors)
          let error_objects = list.map(error_pairs, error_to_json)
          server.json_response(
            422,
            json.object([#("errors", json.array(error_objects, of: fn(x) { x }))])
            |> json.to_string,
          )
        }
        store_validation.Valid -> {
          let update_input = data_access.UpdateStoreInput(
            name: name_opt,
            address: address_opt,
            city: city_opt,
            phone: phone_opt,
          )

          let #(_, update_result) = data_access.update(state, store_id, update_input)

          case update_result {
            Error(_) -> store_not_found_empty()
            Ok(updated_store) -> {
              let response_obj = json.object([
                #("id", json.string(updated_store.id)),
                #("name", json.string(updated_store.name)),
                #("address", case updated_store.address {
                  Some(addr) -> json.string(addr)
                  None -> json.null()
                }),
                #("city", case updated_store.city {
                  Some(city) -> json.string(city)
                  None -> json.null()
                }),
                #("phone", case updated_store.phone {
                  Some(phone) -> json.string(phone)
                  None -> json.null()
                }),
                #("updated_at", json.string(updated_store.updated_at)),
              ])
              server.json_response(200, json.to_string(response_obj))
            }
          }
        }
      }
    }
  }
}
