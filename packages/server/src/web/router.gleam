import gleam/json
import gleam/option.{None, Some}
import gleam/string
import shared
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
    "GET", path -> route_get(path)
    _, _ -> not_found()
  }
}

fn route_get(path: String) -> Response {
  case string.starts_with(path, "/static/") {
    True -> static.serve(path)
    False -> {
      case extract_api_todo_id(path) {
        Some(id) -> get_todo_handler(id)
        None -> not_found()
      }
    }
  }
}

// Extract todo ID from /api/todos/:id pattern
fn extract_api_todo_id(path: String) -> option.Option(String) {
  let segments = string.split(path, "/")
  case segments {
    ["", "api", "todos", id] -> {
      case is_valid_id_format(id) {
        True -> Some(id)
        False -> Some(id)
        // Return the ID anyway, handler will validate
      }
    }
    _ -> None
  }
}

// Validate that ID is non-empty and doesn't contain path traversal or special chars
fn is_valid_id_format(id: String) -> Bool {
  let trimmed = string.trim(id)
  case trimmed {
    "" -> False
    _ -> {
      // Check for path traversal or invalid characters
      case
        string.contains(trimmed, "/")
        || string.contains(trimmed, "..")
        || string.contains(trimmed, "\\")
        || string.contains(trimmed, "<")
        || string.contains(trimmed, ">")
        || string.contains(trimmed, "#")
        || string.contains(trimmed, "%")
        || string.contains(trimmed, "@")
        || string.contains(trimmed, "$")
      {
        True -> False
        False -> True
      }
    }
  }
}

// Handle GET /api/todos/:id request
fn get_todo_handler(id: String) -> Response {
  // Validate ID format first
  case is_valid_id_format(id) {
    False -> {
      server.json_response(
        400,
        json.object([#("error", json.string("Invalid ID format"))])
        |> json.to_string,
      )
    }
    True -> {
      case todo_store.get_by_id(id) {
        Some(found) -> {
          server.json_response(
            200,
            shared.todo_to_json(found),
          )
        }
        None -> {
          server.json_response(
            404,
            json.object([#("error", json.string("Todo not found"))])
            |> json.to_string,
          )
        }
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
