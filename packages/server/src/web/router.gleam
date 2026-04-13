import gleam/dict
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/string
import todo_actor.{type TodoActor}
import web/server.{type Request, type Response}
import web/static

pub fn make_handler(todo_actor: TodoActor) -> fn(Request) -> Response {
  fn(request: Request) { route(request, todo_actor) }
}

fn route(request: Request, todo_actor: TodoActor) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "DELETE", path -> route_delete(path, todo_actor)
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

fn route_delete(path: String, todo_actor: TodoActor) -> Response {
  case extract_api_todo_id(path) {
    Some(id) -> delete_todo_handler(todo_actor, id)
    None -> not_found()
  }
}

/// Extract todo ID from /api/todos/:id path pattern
fn extract_api_todo_id(path: String) -> Option(String) {
  case string.starts_with(path, "/api/todos/") {
    True -> {
      let id_part = string.slice(path, 11, string.length(path) - 11)
      case string.is_empty(id_part) {
        False -> Some(id_part)
        True -> None
      }
    }
    False -> None
  }
}

fn delete_todo_handler(todo_actor: TodoActor, id: String) -> Response {
  case todo_actor.delete(todo_actor, id) {
    Ok(_) -> no_content_response()
    Error(_) -> todo_not_found()
  }
}

fn no_content_response() -> Response {
  server.Response(
    status: 204,
    headers: dict.new(),
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
