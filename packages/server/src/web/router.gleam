import gleam/json
import gleam/int
import gleam/option.{None, Some}
import gleam/string
import drink_store.{type DrinkStore}
import rating_service.{type RatingService}
import store/store_data_access as store_access
import web/handlers/drink_handler
import web/handlers/store_list_handler
import web/server.{type Request, type Response}
import web/static

pub fn make_handler() -> fn(Request) -> Response {
  fn(request: Request) { route(request) }
}

fn route(request: Request) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "GET", path -> route_get(request, path)
    _, _ -> not_found()
  }
}

fn route_get(request: Request, path: String) -> Response {
  // Check for static files first
  case string.starts_with(path, "/static/") {
    True -> static.serve(path)
    False -> {
      // Check for API routes
      case path {
        "/api/stores" -> store_list_handler.handle_list_stores(request)
        _ -> {
          case string.starts_with(path, "/api/stores/") && string.ends_with(path, "/drinks") {
            True -> {
              // Initialize services for the handler
              // In a production app, these would be passed via supervision tree
              case initialize_services() {
                Ok(#(drink_store_ref, store_state, rating_service_ref)) -> {
                  drink_handler.list_drinks_by_store(
                    drink_store_ref,
                    store_state,
                    rating_service_ref,
                    path,
                  )
                }
                Error(_) -> {
                  server.json_response(
                    500,
                    json.object([#("error", json.string("Service initialization failed"))])
                    |> json.to_string,
                  )
                }
              }
            }
            False -> not_found()
          }
        }
      }
    }
  }
}

/// Initialize service dependencies
/// In a full OTP setup, these would be started by the supervisor and passed to the handler
fn initialize_services() -> Result(#(DrinkStore, store_access.StoreState, RatingService), String) {
  // Start drink store
  case drink_store.start() {
    Error(err) -> Error("Failed to start drink store: " <> err)
    Ok(drink_store_ref) -> {
      // Start rating service (depends on drink store)
      case rating_service.start(drink_store_ref) {
        Error(err) -> Error("Failed to start rating service: " <> err)
        Ok(rating_service_ref) -> {
          // Create empty store state
          let store_state = store_access.new_state()
          Ok(#(drink_store_ref, store_state, rating_service_ref))
        }
      }
    }
  }
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
