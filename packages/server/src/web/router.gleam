import data/drink_store.{type StoreMessage}
import gleam/erlang/process.{type Subject}
import gleam/json
import gleam/option
import gleam/string
import web/handlers/store_handlers
import web/server.{type Request, type Response}
import web/static
import web/controller/drink_controller
import web/service/drink_service

/// Create handler without store (for backward compatibility)
pub fn make_handler() -> fn(Request) -> Response {
  // Initialize drink store (in production, would use persistent storage)
  let drink_store = drink_service.new_store()

  fn(request: Request) { route(request, drink_store) }
}

fn route(request: Request, drink_store: drink_service.DrinkStore) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "GET", "/api/drinks/" <> id -> drink_controller.get_drink(drink_store, id)
    "PATCH", "/api/drinks/" <> id -> drink_controller.patch_drink(drink_store, request, id)
    "GET", path -> route_get(path)
    _, _ -> not_found()
  }
}

fn route_get(request: Request, path: String) -> Response {
  case string.starts_with(path, "/static/") {
    True -> static.serve(path)
    False -> route_api_get(request, path)
  }
}

fn route_api_get(request: Request, path: String) -> Response {
  // Check for /api/stores/:store_id/drinks pattern
  case string.starts_with(path, "/api/stores/")
    && string.ends_with(path, "/drinks") {
    True -> store_handlers.list_drinks_handler(request)
    False -> not_found()
  }
}

fn health_handler() -> Response {
  json_response(
    200,
    json.object([#("status", json.string("ok"))])
    |> json.to_string,
  )
}

fn get_drink_handler(drink_id: String, maybe_store: option.Option(StoreActor)) -> Response {
  case maybe_store {
    option.None -> not_found()
    option.Some(store) -> {
      let store_state = store_actor.get_state(store)
      case drink_store.get_drink_by_id(store_state, drink_id) {
        option.Some(drink_details) -> {
          let body = drink.encode_drink_with_details(drink_details)
            |> json.to_string
          server.json_response(200, body)
        }
        option.None -> not_found()
      }
    }
  }
}

fn not_found() -> Response {
  json_response(
    404,
    json.object([#("error", json.string("Not found"))])
    |> json.to_string,
  )
}
