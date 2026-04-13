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
import store/store_service
import store/store_validation
import web/server.{type Request, type Response}
import web/static

/// Services container for dependency injection
pub type StoreServices {
  StoreServices(
    store_service: store_service.StoreService,
    rating_service: RatingService,
  )
}

/// Context holds service dependencies for the router (legacy, for backward compatibility)
pub type Context {
  Context(rating_service: RatingService)
}

/// Router handler function
pub fn make_handler() -> fn(Request) -> Response {
  fn(request: Request) { route(request, None) }
}

/// Make a handler with services injected via context
pub fn make_handler_with_context(ctx: Context) -> fn(Request) -> Response {
  fn(request: Request) { route_with_context(request, ctx) }
}

/// Make handler with services for production use
pub fn make_handler_with_services(services: StoreServices) -> fn(Request) -> Response {
  fn(request: Request) { route(request, Some(services)) }
}

/// Main routing logic
fn route(request: Request, services: Option(StoreServices)) -> Response {
  case request.method, request.path {
    "POST", "/api/stores" -> handle_create_store(request, services)
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "PUT", path -> route_put(path, request, services)
    "GET", path -> route_get(path, request, services)
    _, _ -> not_found()
  }
}

/// Main routing logic with context (legacy)
fn route_with_context(request: Request, ctx: Context) -> Response {
  case request.method, request.path {
    "POST", "/api/stores" -> handle_create_store_with_rating(request, ctx)
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "PUT", path -> route_put_with_context(path, request, ctx)
    "GET", path -> route_get_with_context(path, request, ctx)
    _, _ -> not_found()
  }
}

/// Route PUT requests for stores
fn route_put(path: String, request: Request, _services: Option(StoreServices)) -> Response {
  case string.starts_with(path, "/api/stores/") {
    True -> update_store_handler(path, request)
    False -> not_found()
  }
}

/// Route PUT requests with context
fn route_put_with_context(path: String, request: Request, _ctx: Context) -> Response {
  case string.starts_with(path, "/api/stores/") {
    True -> update_store_handler(path, request)
    False -> not_found()
  }
}

/// Handler for POST /api/stores - creates a new boba store
fn handle_create_store(request: Request, services: Option(StoreServices)) -> Response {
  // Get store service from services or create fresh one for testing
  let store_srv = case services {
    Some(s) -> s.store_service
    None -> {
      // In test mode, start a fresh service
      let assert Ok(svc) = store_service.start()
      svc
    }
  }

  // Parse request body
  case parse_store_input(request.body) {
    Error(err_msg) -> {
      // Invalid JSON or missing required fields
      server.json_response(422, json.object([
        #("errors", json.array([json.object([
          #("field", json.string("body")),
          #("message", json.string(err_msg))
        ])], of: fn(x) { x }))
      ]) |> json.to_string)
    }
    Ok(input) -> {
      // Call store service to create store
      case store_service.create_store(store_srv, input) {
        Error(service_err) -> {
          server.json_response(500, json.object([
            #("error", json.string(service_err))
          ]) |> json.to_string)
        }
        Ok(result) -> {
          case result {
            store_service.CreateStoreSuccess(store) -> {
              // Return 201 with created store
              let response_body = json.object([
                #("id", json.string(store.id)),
                #("name", json.string(store.name)),
                #("address", json.string(option.unwrap(store.address, ""))),
                #("city", json.string(option.unwrap(store.city, ""))),
                #("phone", json.string(option.unwrap(store.phone, ""))),
                #("created_at", json.string(store.created_at))
              ])
              server.json_response(201, response_body |> json.to_string)
            }
            store_service.CreateStoreValidationError(errors) -> {
              // Return 422 with validation errors
              let error_objects = list.map(errors, fn(error) {
                let #(field, message) = error
                json.object([
                  #("field", json.string(field)),
                  #("message", json.string(message))
                ])
              })
              server.json_response(422, json.object([
                #("errors", json.array(error_objects, of: fn(x) { x }))
              ]) |> json.to_string)
            }
            store_service.CreateStoreDuplicateError -> {
              // Return 409 conflict
              server.json_response(409, json.object([
                #("error", json.string("store name already exists"))
              ]) |> json.to_string)
            }
          }
        }
      }
    }
  }
}

/// Handler for POST /api/stores with context (legacy)
fn handle_create_store_with_rating(request: Request, _ctx: Context) -> Response {
  // For legacy context mode, just call handle_create_store with no services
  handle_create_store(request, None)
}

/// Parse store input from JSON body
fn parse_store_input(body: String) -> Result(store_service.CreateStoreInput, String) {
  // Parse JSON to dynamic value first
  case json.parse(body, decode.dynamic) {
    Error(_) -> Error("Invalid JSON payload")
    Ok(dynamic_value) -> {
      // Define decoder using the use syntax
      let decoder = {
        use name <- decode.field("name", decode.string)
        use address <- decode.optional_field("address", None, decode.optional(decode.string))
        use city <- decode.optional_field("city", None, decode.optional(decode.string))
        use phone <- decode.optional_field("phone", None, decode.optional(decode.string))
        decode.success(store_service.CreateStoreInput(
          name: name,
          address: address,
          city: city,
          phone: phone,
        ))
      }

      // Run the decoder
      case decode.run(dynamic_value, decoder) {
        Ok(input) -> Ok(input)
        Error(_) -> Error("Missing or invalid required fields")
      }
    }
  }
}

/// Handle GET requests
fn route_get(path: String, request: Request, services: Option(StoreServices)) -> Response {
  case string.starts_with(path, "/static/") {
    True -> static.serve(path)
    False -> {
      // Check for /api/drinks/:id/ratings pattern
      case parse_drink_ratings_path(path) {
        Some(drink_id) -> {
          case services {
            Some(s) -> get_drink_ratings_handler(drink_id, request, s.rating_service)
            None -> not_found()
          }
        }
        None -> not_found()
      }
    }
  }
}

/// Handle GET requests with context (legacy)
fn route_get_with_context(path: String, request: Request, ctx: Context) -> Response {
  case string.starts_with(path, "/static/") {
    True -> static.serve(path)
    False -> {
      // Check for /api/drinks/:id/ratings pattern
      case parse_drink_ratings_path(path) {
        Some(drink_id) -> get_drink_ratings_handler(drink_id, request, ctx.rating_service)
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
    _, _ -> route(request, None)
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
fn get_drink_ratings_handler(drink_id: String, request: Request, rating_svc: RatingService) -> Response {
  let params = parse_query_params(request.path)
  let limit = get_int_param(params, "limit", 20)
  let offset = get_int_param(params, "offset", 0)

  case rating_service.list_ratings_by_drink_paginated(rating_svc, drink_id, limit, offset) {
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

// Public handler for testing - exposed for test compatibility
pub fn handle_request_test(request: Request) -> Response {
  route(request, None)
}
