import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import shared.{type Todo}
import todo_store
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
    "GET", "/api/todos" -> list_todos_handler(request)
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

/// Parse completed query parameter from request path
/// Returns Some(True) for "?completed=true", Some(False) for "?completed=false", None otherwise
fn parse_completed_filter(request: Request) -> Option(Bool) {
  case string.contains(request.path, "?completed=true") {
    True -> Some(True)
    False -> {
      case string.contains(request.path, "?completed=false") {
        True -> Some(False)
        False -> None
      }
    }
  }
}

/// Convert a list of Todos to JSON array string
fn todos_to_json(todos: List(Todo)) -> String {
  let json_objects = list.map(todos, fn(t) { shared.todo_to_json(t) })
  "[" <> string.join(json_objects, ",") <> "]"
}

fn list_todos_handler(request: Request) -> Response {
  let todos = case parse_completed_filter(request) {
    Some(completed) -> todo_store.get_by_completed(completed)
    None -> todo_store.get_all()
  }

  server.json_response(200, todos_to_json(todos))
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
