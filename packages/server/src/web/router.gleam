import gleam/dict.{type Dict}
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import todo_store.{type TodoStore, type TodoItem}
import web/server.{type Request, type Response}
import web/static

pub fn make_handler(store: TodoStore) -> fn(Request) -> Response {
  fn(request: Request) { route(request, store) }
}

fn route(request: Request, store: TodoStore) -> Response {
  // Extract path without query string for routing
  let path_only = case string.split(request.path, "?") {
    [path, _] -> path
    _ -> request.path
  }

  case request.method, path_only {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "GET", "/api/todos" -> list_todos_handler(request, store)
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

// Parse filter query parameter from request
fn get_filter_param(request: Request) -> String {
  // Extract query string from path
  case string.split(request.path, "?") {
    [_, query] -> {
      // Parse query parameters
      let params = parse_query_string(query)
      case dict.get(params, "filter") {
        Ok(value) -> string.lowercase(value)
        Error(_) -> "all"
      }
    }
    _ -> "all"
  }
}

// Parse query string into key-value pairs
fn parse_query_string(query: String) -> Dict(String, String) {
  let pairs = string.split(query, "&")
  list.fold(pairs, dict.new(), fn(acc, pair) {
    case string.split(pair, "=") {
      [key, value] -> dict.insert(acc, key, value)
      _ -> acc
    }
  })
}

// Filter todos based on completion status
fn filter_todos(todos: List(TodoItem), filter: String) -> List(TodoItem) {
  case filter {
    "active" -> list.filter(todos, fn(t) { !t.completed })
    "completed" -> list.filter(todos, fn(t) { t.completed })
    _ -> todos
  }
}

// Sort todos by created_at descending (newest first)
fn sort_todos_desc(todos: List(TodoItem)) -> List(TodoItem) {
  list.sort(todos, fn(a, b) {
    string.compare(b.created_at, a.created_at)
  })
}

// Convert TodoItem to JSON
fn todo_item_to_json(item: TodoItem) -> json.Json {
  let description_value = case item.description {
    Some(desc) -> json.string(desc)
    None -> json.null()
  }

  let priority_str = case item.priority {
    todo_store.Low -> "low"
    todo_store.Medium -> "medium"
    todo_store.High -> "high"
  }

  json.object([
    #("id", json.string(item.id)),
    #("title", json.string(item.title)),
    #("description", description_value),
    #("priority", json.string(priority_str)),
    #("completed", json.bool(item.completed)),
    #("created_at", json.string(item.created_at)),
    #("updated_at", json.string(item.updated_at)),
  ])
}

// Handler for GET /api/todos
fn list_todos_handler(request: Request, store: TodoStore) -> Response {
  let filter = get_filter_param(request)
  let todos = todo_store.list(store)
  let filtered = filter_todos(todos, filter)
  let sorted = sort_todos_desc(filtered)

  let json_array = json.array(sorted, todo_item_to_json)
  let body = json.to_string(json_array)

  server.json_response(200, body)
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
