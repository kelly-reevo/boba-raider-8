import gleam/json
import gleam/string
import todo_store.{type TodoStore}
import web/server.{type Request, type Response}
import web/static
import web/todos

pub fn make_handler(store: TodoStore) -> fn(Request) -> Response {
  fn(request: Request) { route(store, request) }
}

fn route(store: TodoStore, request: Request) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "POST", path -> route_post(store, path, request)
    "PATCH", path -> route_patch(store, path, request)
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

fn route_patch(store: TodoStore, path: String, request: Request) -> Response {
  case string.starts_with(path, "/api/todos/") {
    True -> todos.patch_todo(store, request)
    False -> not_found()
  }
}

fn route_post(store: TodoStore, path: String, request: Request) -> Response {
  case path {
    "/api/todos" -> todos.create_todo(store, request)
    _ -> not_found()
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
