import data/drink_store.{type StoreMessage}
import gleam/erlang/process.{type Subject}
import gleam/json
import gleam/option
import gleam/string
import storage/store.{type Store}
import web/handlers/drink_handler
import web/server.{type Request, type Response, json_response}
import web/static
import web/controller/drink_controller
import web/service/drink_service

/// Create request handler with access to store
pub fn make_handler(store: Store) -> fn(Request) -> Response {
  fn(request: Request) { route(store, request) }
}

fn route(store: Store, request: Request) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "DELETE", path -> route_delete(store, request, path)
    "GET", path -> route_get(path)
    _, _ -> not_found()
  }
}

fn route_delete(store: Store, request: Request, path: String) -> Response {
  // DELETE /api/drinks/:id
  case string.starts_with(path, "/api/drinks/") {
    True -> {
      let drink_id = string.drop_start(path, string.length("/api/drinks/"))
      case drink_id {
        "" -> not_found()
        _ -> drink_handler.delete(store, request, drink_id)
      }
    }
    False -> not_found()
  }
}

fn route_get(path: String) -> Response {
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
    |> json.to_string(),
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
    |> json.to_string(),
  )
}
