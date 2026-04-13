import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import store/store_service
import web/server.{type Request, type Response}
import web/static

/// Services container for dependency injection
pub type StoreServices {
  StoreServices(
    store_service: store_service.StoreService,
  )
}

/// Make handler without state (backward compatible, creates fresh services per request for tests)
pub fn make_handler() -> fn(Request) -> Response {
  fn(request: Request) { route(request, None) }
}

/// Make handler with services for production use
pub fn make_handler_with_services(services: StoreServices) -> fn(Request) -> Response {
  fn(request: Request) { route(request, Some(services)) }
}

fn route(request: Request, services: Option(StoreServices)) -> Response {
  case request.method, request.path {
    "POST", "/api/stores" -> handle_create_store(request, services)
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "GET", path -> route_get(path)
    _, _ -> not_found()
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

fn route_get(path: String) -> Response {
  case string.starts_with(path, "/static/") {
    True -> static.serve(path)
    False -> not_found()
  }
}

// Public handler for testing - exposed for test compatibility
pub fn handle_request(request: Request) -> Response {
  route(request, None)
}

fn health_handler() -> Response {
  server.json_response(
    200,
    json.object([#("status", json.string("ok"))])
    |> json.to_string,
  )
}

fn not_found() -> Response {
  server.json_response(
    404,
    json.object([#("error", json.string("Not found"))])
    |> json.to_string,
  )
}
