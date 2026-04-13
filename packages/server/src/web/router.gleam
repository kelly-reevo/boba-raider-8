import gleam/dict.{type Dict}
import gleam/dynamic
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import rating_service.{type RatingService}
import store/store_data_access as data_access
import store/store_validation
import web/server.{type Request, type Response}
import web/static

/// Context holds service dependencies for the router
pub type Context {
  Context(rating_service: RatingService)
}

/// Router handler function
pub fn make_handler() -> fn(Request) -> Response {
  fn(request: Request) { route(request) }
}

/// Make a handler with services injected via context
pub fn make_handler_with_context(ctx: Context) -> fn(Request) -> Response {
  fn(request: Request) { route_with_context(request, ctx) }
}

/// Main routing logic (without context - legacy)
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

/// Main routing logic with context
fn route_with_context(request: Request, ctx: Context) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "PUT", path -> route_put(path, request)
    "GET", path -> route_get_with_context(path, request, ctx)
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

/// Handle GET requests (without context)
fn route_get(path: String) -> Response {
  case string.starts_with(path, "/static/") {
    True -> static.serve(path)
    False -> not_found()
  }
}

/// Handle GET requests with context
fn route_get_with_context(path: String, request: Request, ctx: Context) -> Response {
  case string.starts_with(path, "/static/") {
    True -> static.serve(path)
    False -> {
      // Check for /api/drinks/:id/ratings pattern
      case parse_drink_ratings_path(path) {
        Some(drink_id) -> get_drink_ratings_handler(drink_id, request, ctx)
        None -> not_found()
      }
    }
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

/// Parse /api/drinks/:id/ratings pattern
fn parse_drink_ratings_path(path: String) -> option.Option(String) {
  let parts = string.split(path, "/")
  case parts {
    ["", "api", "drinks", drink_id, "ratings"] -> Some(drink_id)
    _ -> None
  }
}

/// Parse query parameters from path (e.g., "?limit=10&offset=5")
fn parse_query_params(path: String) -> dict.Dict(String, String) {
  case string.split(path, "?") {
    [_, query_string] -> {
      query_string
      |> string.split("&")
      |> list.fold(dict.new(), fn(acc, pair) {
        case string.split(pair, "=") {
          [key, value] -> dict.insert(acc, key, value)
          _ -> acc
        }
      })
    }
    _ -> dict.new()
  }
}

/// Get integer query param with default
fn get_int_param(params: dict.Dict(String, String), key: String, default: Int) -> Int {
  case dict.get(params, key) {
    Ok(value) -> result.unwrap(int.parse(value), default)
    Error(_) -> default
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

/// Convert error pairs to JSON objects
fn error_to_json(pair: #(String, String)) -> json.Json {
  json.object([
    #("field", json.string(pair.0)),
    #("message", json.string(pair.1)),
  ])
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

/// Handler for GET /api/drinks/:id/ratings
fn get_drink_ratings_handler(drink_id: String, request: Request, ctx: Context) -> Response {
  let params = parse_query_params(request.path)
  let limit = get_int_param(params, "limit", 20)
  let offset = get_int_param(params, "offset", 0)

  case rating_service.list_ratings_by_drink_paginated(ctx.rating_service, drink_id, limit, offset) {
    Ok(result) -> {
      let ratings_json = json.array(result.ratings, fn(rating) {
        json.object([
          #("id", json.string(rating.id)),
          #("overall_rating", json.int(rating.overall_rating)),
          #("sweetness", json.int(rating.sweetness)),
          #("boba_texture", json.int(rating.boba_texture)),
          #("tea_strength", json.int(rating.tea_strength)),
          #("created_at", json.string(int.to_string(rating.created_at))),
        ])
      })

      let response = json.object([
        #("ratings", ratings_json),
        #("total", json.int(result.total)),
        #("limit", json.int(result.limit)),
        #("offset", json.int(result.offset)),
      ])

      server.json_response(200, json.to_string(response))
    }
    Error(_) -> not_found()
  }
}
