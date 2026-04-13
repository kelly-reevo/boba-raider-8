import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/string
import models/todo_item.{type Todo}
import todo_store.{type Store}
import web/server.{type Request, type Response}
import web/static

/// Create a request handler with the given store
pub fn make_handler_with_store(store: Store) -> fn(Request) -> Response {
  fn(request: Request) { route(request, store) }
}

/// Create a request handler with a fresh store
pub fn make_handler() -> fn(Request) -> Response {
  fn(request: Request) {
    let assert Ok(store) = todo_store.start()
    route(request, store)
  }
}

fn route(request: Request, store: Store) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "GET", path -> route_get(path, store)
    _, _ -> not_found()
  }
}

fn route_get(path: String, store: Store) -> Response {
  case string.starts_with(path, "/static/") {
    True -> static.serve(path)
    False -> route_api_get(path, store)
  }
}

fn route_api_get(path: String, store: Store) -> Response {
  case extract_todo_id_from_path(path) {
    Some(id) -> handle_get_todo(id, store)
    None -> not_found()
  }
}

/// Extract todo id from path like /api/todos/:id
fn extract_todo_id_from_path(path: String) -> Option(String) {
  case string.starts_with(path, "/api/todos/") {
    True -> {
      let id = string.drop_start(path, 11)
      case id {
        "" -> option.None
        _ -> option.Some(id)
      }
    }
    False -> option.None
  }
}

/// Handle GET /api/todos/:id
fn handle_get_todo(id: String, store: Store) -> Response {
  // Validate UUID format
  case is_valid_uuid(id) {
    False -> bad_request_or_not_found()
    True -> {
      case todo_store.get_todo(store, id) {
        Ok(found_todo) -> json_response(200, todo_to_json(found_todo))
        Error(_) -> not_found_with_message("Todo not found")
      }
    }
  }
}

/// Check if a string looks like a valid UUID format
/// UUID format: 8-4-4-4-12 hex characters (36 chars total with dashes)
fn is_valid_uuid(id: String) -> Bool {
  // Manual validation to avoid regex dependency
  // Format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx (36 chars)
  case string.length(id) {
    36 -> {
      // Check dash positions at indices 8, 13, 18, 23
      case
        string.slice(id, 8, 1),
        string.slice(id, 13, 1),
        string.slice(id, 18, 1),
        string.slice(id, 23, 1)
      {
        "-", "-", "-", "-" -> {
          // Remove dashes and check all remaining chars are hex
          let hex_part = string.replace(id, "-", "")
          is_all_hex(hex_part)
        }
        _, _, _, _ -> False
      }
    }
    _ -> False
  }
}

/// Check if all characters in a string are valid hex characters
fn is_all_hex(s: String) -> Bool {
  let hex_chars = "0123456789abcdefABCDEF"
  check_all_chars_in_set(s, hex_chars)
}

fn check_all_chars_in_set(s: String, valid_set: String) -> Bool {
  case string.pop_grapheme(s) {
    Error(Nil) -> True
    Ok(#(char, rest)) -> {
      case string.contains(valid_set, char) {
        True -> check_all_chars_in_set(rest, valid_set)
        False -> False
      }
    }
  }
}

/// Convert a Todo to JSON string
fn todo_to_json(item: Todo) -> String {
  let description_json = case item.description {
    option.Some(desc) -> json.string(desc)
    option.None -> json.null()
  }

  json.object([
    #("id", json.string(item.id)),
    #("title", json.string(item.title)),
    #("description", description_json),
    #("priority", json.string(todo_item.priority_to_string(item.priority))),
    #("completed", json.bool(item.completed)),
    #("created_at", json.string(item.created_at)),
  ])
  |> json.to_string
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

/// Helper: Create JSON response with specific status
fn json_response(status: Int, body: String) -> Response {
  server.json_response(status, body)
}

/// Helper: Return 404 with specific error message
fn not_found_with_message(message: String) -> Response {
  server.json_response(
    404,
    json.object([#("error", json.string(message))])
    |> json.to_string,
  )
}

/// Helper: Return error for invalid UUID (400 or 404 acceptable per tests)
fn bad_request_or_not_found() -> Response {
  server.json_response(
    404,
    json.object([#("error", json.string("Not found"))])
    |> json.to_string,
  )
}
