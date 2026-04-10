import gleam/erlang/process.{type Subject}
import gleam/json
import gleam/string
import store/store_actor.{type StoreMessage}
import web/handlers/store_handler
import web/server.{type Request, type Response}
import web/static

pub fn make_handler(
  store_actor: Subject(StoreMessage),
) -> fn(Request) -> Response {
  fn(request: Request) { route(request, store_actor) }
}

fn route(request: Request, store_actor: Subject(StoreMessage)) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()

    // Store API routes
    "DELETE", path -> {
      case is_store_path(path) {
        True -> store_handler.delete_store_handler(request, store_actor)
        False -> not_found()
      }
    }

    "GET", path -> route_get(path)
    _, _ -> not_found()
  }
}

// Check if path matches /api/stores/:id pattern
fn is_store_path(path: String) -> Bool {
  case string.split(path, "/") {
    ["", "api", "stores", _] -> True
    _ -> False
  }
}

fn route_get(path: String) -> Response {
  case string.starts_with(path, "/static/") {
    True -> static.serve(path)
    False -> not_found()
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
