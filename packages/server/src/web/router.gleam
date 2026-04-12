import gleam/json
import gleam/list
import gleam/string
import gleam/dict.{type Dict}
import shared.{type Todo}
import todo_store.{type Store}
import web/server.{type Request, type Response}
import web/static

pub fn make_handler(store: Store) -> fn(Request) -> Response {
  fn(request: Request) { route(store, request) }
}

fn route(store: Store, request: Request) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "GET", "/api/todos" -> list_todos_handler(store, request)
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

/// Parse query string and return dict of parameters
fn parse_query_params(path: String) -> Dict(String, String) {
  case string.split(path, "?") {
    [_, query_string] -> parse_params(query_string)
    _ -> dict.new()
  }
}

/// Parse a query string into key-value pairs
fn parse_params(query_string: String) -> Dict(String, String) {
  case string.is_empty(query_string) {
    True -> dict.new()
    False -> {
      let pairs = string.split(query_string, "&")
      list.fold(pairs, dict.new(), fn(acc, pair) {
        case string.split(pair, "=") {
          [key, value] -> dict.insert(acc, key, value)
          _ -> acc
        }
      })
    }
  }
}

/// Get filter value from query params, default to "all"
fn get_filter_param(params: Dict(String, String)) -> String {
  case dict.get(params, "filter") {
    Ok(filter) -> filter
    Error(_) -> "all"
  }
}

/// Filter todos based on completion status
fn filter_todos(todos: List(Todo), filter: String) -> List(Todo) {
  case filter {
    "active" -> list.filter(todos, fn(t) { !t.completed })
    "completed" -> list.filter(todos, fn(t) { t.completed })
    _ -> todos
  }
}

/// Serialize a list of todos to JSON array
fn todos_to_json(todos: List(Todo)) -> String {
  let json_items = list.map(todos, fn(item) { shared.todo_to_json(item) })
  "[" <> string.join(json_items, ",") <> "]"
}

fn list_todos_handler(store: Store, request: Request) -> Response {
  let params = parse_query_params(request.path)
  let filter = get_filter_param(params)
  let todos = todo_store.get_all_todos(store)
  let filtered = filter_todos(todos, filter)
  let json_body = todos_to_json(filtered)

  server.json_response(200, json_body)
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
