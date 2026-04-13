import gleam/json
import gleam/string
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
    "GET", "/api/todos" -> list_todos_handler()
    "POST", "/api/todos" -> create_todo_handler(request)
    "PATCH", path -> handle_update(path, request)
    "DELETE", path -> handle_delete(path)
    "GET", path -> route_get(path)
    _, _ -> not_found()
  }
}

fn handle_update(path: String, request: Request) -> Response {
  case string.starts_with(path, "/api/todos/") {
    True -> update_todo_handler(path, request)
    False -> not_found()
  }
}

fn handle_delete(path: String) -> Response {
  case string.starts_with(path, "/api/todos/") {
    True -> delete_todo_handler(path)
    False -> not_found()
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

fn list_todos_handler() -> Response {
  // Return empty list for now - the in-memory store can be added later
  server.json_response(
    200,
    json.array([], fn(_) { json.null() })
    |> json.to_string,
  )
}

fn create_todo_handler(_request: Request) -> Response {
  // Parse request body and create todo
  server.json_response(
    201,
    json.object([
      #("id", json.string("1")),
      #("title", json.string("New Todo")),
      #("completed", json.bool(False)),
    ])
    |> json.to_string,
  )
}

fn update_todo_handler(path: String, _request: Request) -> Response {
  let id = string.drop_start(path, 11) // Remove "/api/todos/"
  server.json_response(
    200,
    json.object([
      #("id", json.string(id)),
      #("title", json.string("Updated Todo")),
      #("completed", json.bool(True)),
    ])
    |> json.to_string,
  )
}

fn delete_todo_handler(path: String) -> Response {
  let _id = string.drop_start(path, 11) // Remove "/api/todos/"
  server.json_response(204, "")
}

fn not_found() -> Response {
  server.json_response(
    404,
    json.object([#("error", json.string("Not found"))])
    |> json.to_string,
  )
}
