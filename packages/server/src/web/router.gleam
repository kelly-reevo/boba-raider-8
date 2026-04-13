import gleam/dict
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/string
import shared.{NotFound}
import todo_store
import web/server.{type Request, type Response}
import web/static

pub fn make_handler(store: todo_store.TodoStore) -> fn(Request) -> Response {
  fn(request: Request) { route(request, store) }
}

fn route(request: Request, store: todo_store.TodoStore) -> Response {
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

fn route_delete(path: String, store: todo_store.TodoStore) -> Response {
  case extract_api_todo_id(path) {
    Some(id) -> delete_todo_handler(store, id)
    None -> not_found()
  }
}

// Extract todo ID from /api/todos/:id path
fn extract_api_todo_id(path: String) -> Option(String) {
  let prefix = "/api/todos/"
  case string.starts_with(path, prefix) {
    True -> {
      let id = string.drop_start(path, string.length(prefix))
      // Ensure there's an ID and no trailing path segments
      case id {
        "" -> None
        _ -> {
          // Check for path segments (no slashes allowed in ID)
          case string.contains(id, "/") {
            True -> None
            False -> Some(id)
          }
        }
      }
    }
    False -> None
  }
}

fn delete_todo_handler(_store: todo_store.TodoStore, id: String) -> Response {
  case todo_store.delete(id) {
    Ok(_) -> no_content_response()
    Error(NotFound(_)) -> todo_not_found_error()
    Error(_) -> server_error()
  }
}

fn no_content_response() -> Response {
  server.Response(
    status: 204,
    headers: dict.from_list([#("Content-Type", "application/json")]),
    body: "",
  )
}

fn todo_not_found_error() -> Response {
  server.json_response(
    404,
    json.object([#("error", json.string("Todo not found"))])
    |> json.to_string,
  )
}

fn server_error() -> Response {
  server.json_response(
    500,
    json.object([#("error", json.string("Internal server error"))])
    |> json.to_string,
  )
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
