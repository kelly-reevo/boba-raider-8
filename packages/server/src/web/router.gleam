import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import models/todo_item
import todo_actor.{type TodoActor, type Filter, All, Completed}
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
    "GET", "/api/todos" -> list_todos_handler(request, todo_actor)
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

/// Parse query parameters from path string (everything after ?)
fn parse_query_params(path: String) -> List(#(String, String)) {
  case string.split(path, "?") {
    [_, query_string] -> {
      case string.is_empty(query_string) {
        True -> []
        False -> {
          string.split(query_string, "&")
          |> list.filter(fn(s) { !string.is_empty(s) })
          |> list.filter_map(fn(param) {
            case string.split(param, "=") {
              [key, value] -> Ok(#(key, value))
              [key] -> Ok(#(key, ""))
              _ -> Error(Nil)
            }
          })
        }
      }
    }
    _ -> []
  }
}

/// Get a query parameter value by key
fn get_query_param(params: List(#(String, String)), key: String) -> Option(String) {
  case list.find(params, fn(p) { p.0 == key }) {
    Ok(#(_, value)) -> Some(value)
    Error(_) -> None
  }
}

/// Parse the completed filter from query param value
fn parse_completed_filter(value: Option(String)) -> Filter {
  case value {
    Some("true") -> Completed(True)
    Some("false") -> Completed(False)
    _ -> All
  }
}

/// Handler for GET /api/todos
/// Accepts optional `completed` query param: true, false, or omitted
fn list_todos_handler(request: Request, actor: TodoActor) -> Response {
  // Parse query params from the path
  let params = parse_query_params(request.path)

  // Get the completed filter value
  let completed_param = get_query_param(params, "completed")

  // Convert to filter type
  let filter = parse_completed_filter(completed_param)

  // Call the actor to get filtered todos
  let todos = todo_actor.list(actor, filter)

  // Serialize todos to JSON
  let todos_json = list.map(todos, fn(t) {
    json.object([
      #("id", json.string(t.id)),
      #("title", json.string(t.title)),
      #("description", case t.description {
        Some(d) -> json.string(d)
        None -> json.null()
      }),
      #("priority", json.string(todo_item.priority_to_string(t.priority))),
      #("completed", json.bool(t.completed)),
      #("created_at", json.string(t.created_at)),
    ])
  })

  // Build response
  let response_body = json.object([#("todos", json.array(todos_json, of: fn(x) { x }))])

  server.json_response(200, json.to_string(response_body))
}
