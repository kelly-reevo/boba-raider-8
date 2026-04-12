import gleam/dict
import gleam/json
import gleam/option.{None, Some}
import gleam/string
import todo_store.{type TodoStore}
import web/server.{type Request, type Response}
import web/static

pub fn make_handler(store: TodoStore) -> fn(Request) -> Response {
  fn(request: Request) { route(request, store) }
}

fn route(request: Request, store: TodoStore) -> Response {
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

fn route_delete(path: String, store: TodoStore) -> Response {
  case extract_todo_id(path) {
    Some(id) -> delete_todo_handler(store, id)
    None -> not_found()
  }
}

fn extract_todo_id(path: String) -> option.Option(String) {
  // Extract ID from /api/todos/:id pattern
  case string.starts_with(path, "/api/todos/") {
    True -> {
      let prefix_length = 11  // length of "/api/todos/"
      case string.length(path) > prefix_length {
        True -> {
          let id = string.drop_start(path, prefix_length)
          // Return the ID even if it doesn't look like a valid UUID
          // The store will handle the lookup and return NotFound if it doesn't exist
          Some(id)
        }
        False -> None
      }
    }
    False -> None
  }
}

fn delete_todo_handler(store: TodoStore, id: String) -> Response {
  case todo_store.delete(store, id) {
    todo_store.Ok -> no_content()
    todo_store.NotFound -> todo_not_found()
  }
}

fn health_handler() -> Response {
  server.json_response(
    200,
    json.object([#("status", json.string("ok"))])
    |> json.to_string,
  )
}

fn no_content() -> Response {
  server.Response(
    status: 204,
    headers: dict.from_list([#("Content-Type", "application/json")]),
    body: "",
  )
}

fn todo_not_found() -> Response {
  server.json_response(
    404,
    json.object([#("error", json.string("Todo not found"))])
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
