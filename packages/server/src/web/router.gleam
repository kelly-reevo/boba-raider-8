import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
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
    "GET", "/api/todos" -> todos_handler(request)
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

fn todos_handler(request: Request) -> Response {
  // Parse query parameters to get filter
  let filter = parse_filter_param(request.query)

  // Mock todo data for testing
  let all_todos = [
    #("1", "Active Todo 1", False),
    #("2", "Completed Todo", True),
    #("3", "Active Todo 2", False),
  ]

  // Filter todos based on the filter parameter
  let filtered_todos = case filter {
    "active" -> list.filter(all_todos, fn(t) { !t.2 })
    "completed" -> list.filter(all_todos, fn(t) { t.2 })
    _ -> all_todos
  }

  // Convert to JSON
  let todos_json = json.array(filtered_todos, fn(t) {
    json.object([
      #("id", json.string(t.0)),
      #("title", json.string(t.1)),
      #("completed", json.bool(t.2)),
    ])
  })

  server.json_response(200, json.to_string(todos_json))
}

fn parse_filter_param(query: Option(String)) -> String {
  case query {
    None -> "all"
    Some(q) -> {
      case string.split(q, "=") {
        ["filter", value] -> value
        _ -> "all"
      }
    }
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
