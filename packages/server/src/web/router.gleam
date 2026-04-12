import gleam/dict
import gleam/json
import gleam/string
import todo_store.{type Store}
import web/server.{type Request, type Response}
import web/static

pub fn make_handler(store: Store) -> fn(Request) -> Response {
  fn(request: Request) { route(request, store) }
}

fn route(request: Request, store: Store) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "DELETE", path -> route_delete(path, store)
    "GET", path -> route_get(path)
    _, _ -> not_found()
  }
}

fn route_get(path: String) -> Response {
  case string.starts_with(path, "/static/") {
    True -> static.serve(path)
    False -> not_found()
  }
}

fn route_delete(path: String, store: Store) -> Response {
  case string.starts_with(path, "/api/todos/") {
    True -> {
      let id = string.slice(path, 11, string.length(path))
      case string.is_empty(id) {
        True -> not_found()
        False -> delete_todo_handler(store, id)
      }
    }
    False -> not_found()
  }
}

fn delete_todo_handler(store: Store, id: String) -> Response {
  case todo_store.delete_todo(store, id) {
    Ok(_) -> server.Response(status: 204, headers: dict.new(), body: "")
    Error(_) -> not_found()
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
