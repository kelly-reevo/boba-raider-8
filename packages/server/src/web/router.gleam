import gleam/dict
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import shared.{type Todo, type TodoAttrs, type Priority, High, Low, Medium, NotFound, TodoAttrs, todo_to_json}
import todo_store
import web/server.{type Request, type Response}
import web/static

pub fn make_handler(store: todo_store.TodoStore) -> fn(Request) -> Response {
  fn(request: Request) { route(request, store) }
}

fn route(request: Request, store: todo_store.TodoStore) -> Response {
  case request.method, request.path {
    "POST", "/api/todos" -> post_todos_handler(request)
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "GET", "/api/todos" -> list_todos_handler(request)
    "PATCH", path -> route_patch(path, request)
    "DELETE", path -> route_delete(path, store)
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

fn route_patch(path: String, request: Request) -> Response {
  case string.starts_with(path, "/api/todos/") {
    True -> patch_todo_handler(path, request)
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

fn patch_todo_handler(path: String, request: Request) -> Response {
  let id = string.drop_start(path, string.length("/api/todos/"))

  // Parse and validate the patch body
  let patch_result = parse_patch_body(request.body)

  case patch_result {
    Error(errors) ->
      server.json_response(
        422,
        json.object([
          #("errors", json.array(errors, fn(e) {
            json.object([#("field", json.string(e.0)), #("message", json.string(e.1))])
          })),
        ])
        |> json.to_string,
      )

    Ok(#(title_opt, description_opt, priority_opt, completed_opt)) -> {
      case todo_store.patch(id, title_opt, description_opt, priority_opt, completed_opt) {
        Ok(todo_item) -> server.json_response(200, todo_to_json(todo_item))
        Error(_) ->
          server.json_response(
            404,
            json.object([#("error", json.string("Todo not found"))])
            |> json.to_string,
          )
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

fn parse_patch_body(body: String) -> Result(#(Option(String), Option(Option(String)), Option(Priority), Option(Bool)), List(#(String, String))) {
  // For empty body, return all None values (no changes)
  let trimmed = string.trim(body)
  case trimmed {
    "{}" | "" -> Ok(#(None, None, None, None))
    _ -> {
      let errors = []

      // Extract title if present
      let title_opt = extract_optional_string_field(body, "title")
      let errors = case title_opt {
        Some("") -> [#("title", "Title cannot be empty"), ..errors]
        _ -> errors
      }

      // Extract description if present
      let description_opt = extract_nullable_string_field(body, "description")

      // Extract priority if present
      let priority_result = case extract_raw_field(body, "priority") {
        None -> #(None, errors)
        Some("null") -> #(None, errors)
        Some(raw) -> {
          case raw {
            "\"low\"" -> #(Some(Low), errors)
            "\"medium\"" -> #(Some(Medium), errors)
            "\"high\"" -> #(Some(High), errors)
            _ -> #(None, [#("priority", "Invalid priority value"), ..errors])
          }
        }
      }
      let priority_opt = priority_result.0
      let errors = priority_result.1

      // Extract completed if present
      let completed_opt = case extract_raw_field(body, "completed") {
        None -> None
        Some("true") -> Some(True)
        Some("false") -> Some(False)
        _ -> None
      }

      case errors {
        [] -> Ok(#(title_opt, description_opt, priority_opt, completed_opt))
        _ -> Error(errors)
      }
    }
  }
}

fn extract_optional_string_field(json: String, field: String) -> Option(String) {
  case extract_raw_field(json, field) {
    None -> None
    Some(raw) -> {
      case raw {
        "\"" <> rest -> {
          case string.split(rest, "\"") {
            [value, ..] -> Some(value)
            _ -> None
          }
        }
        _ -> None
      }
    }
  }
}

fn extract_nullable_string_field(json: String, field: String) -> Option(Option(String)) {
  case extract_raw_field(json, field) {
    None -> None
    Some("null") -> Some(None)
    Some(raw) -> {
      case raw {
        "\"" <> rest -> {
          case string.split(rest, "\"") {
            [value, ..] -> Some(Some(value))
            _ -> None
          }
        }
        _ -> None
      }
    }
  }
}

fn extract_raw_field(json: String, field: String) -> Option(String) {
  let pattern = "\"" <> field <> "\":"
  case string.split(json, pattern) {
    [_, rest] -> {
      let rest = string.trim_start(rest)
      // Find the value - could be string, bool, null, or number
      case rest {
        "null" <> _ -> Some("null")
        "true" <> _ -> Some("true")
        "false" <> _ -> Some("false")
        "\"" <> quoted -> {
          case string.split(quoted, "\"") {
            [value, ..] -> Some("\"" <> value <> "\"")
            _ -> None
          }
        }
        _ -> {
          // Try to extract number or other value until next comma or brace
          case string.split(rest, ",") {
            [before_comma, ..] -> {
              case string.split(before_comma, "}") {
                [before_brace, ..] -> Some(string.trim(before_brace))
                _ -> Some(string.trim(before_comma))
              }
            }
            _ -> {
              case string.split(rest, "}") {
                [before_brace, ..] -> Some(string.trim(before_brace))
                _ -> Some(string.trim(rest))
              }
            }
          }
        }
      }
    }
    _ -> None
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

// Error field for validation response
type ErrorField {
  ErrorField(field: String, message: String)
}

// POST /api/todos handler - creates a new todo
fn post_todos_handler(request: Request) -> Response {
  // Parse request body and validate
  case parse_create_request(request.body) {
    Ok(attrs) -> {
      // Create todo via storage layer
      case todo_store.create(attrs) {
        Ok(item) -> {
          // Return 201 with created todo JSON
          server.json_response(201, todo_to_json(item))
        }
        Error(_) -> {
          // Internal error during creation
          server.json_response(
            500,
            json.object([#("error", json.string("Failed to create todo"))])
            |> json.to_string,
          )
        }
      }
    }
    Error(errors) -> {
      // Return 422 with validation errors
      let error_json = encode_validation_errors(errors)
      server.json_response(422, error_json)
    }
  }
}

// Parse and validate the create request body
fn parse_create_request(body: String) -> Result(TodoAttrs, List(ErrorField)) {
  let errors = []

  // Extract fields from JSON
  let title_result = extract_string_field(body, "title")
  let description_opt = extract_optional_string_field(body, "description")
  let priority_result = extract_optional_string_field(body, "priority")
  let completed_result = extract_optional_bool_field(body, "completed")

  // Validate title (required, non-empty)
  let errors = case title_result {
    Error(_) -> [ErrorField("title", "is required"), ..errors]
    Ok(title) -> {
      case string.trim(title) {
        "" -> [ErrorField("title", "is required"), ..errors]
        _ -> errors
      }
    }
  }

  // Determine priority value and validate
  let priority_value_result = case priority_result {
    None -> Ok(Medium)
    Some("low") -> Ok(Low)
    Some("medium") -> Ok(Medium)
    Some("high") -> Ok(High)
    Some(_invalid) -> Error("must be low, medium, or high")
  }

  // Add priority error if invalid
  let errors = case priority_value_result {
    Error(msg) -> [ErrorField("priority", msg), ..errors]
    Ok(_) -> errors
  }

  // Get the priority value for construction (default to Medium if error)
  let priority_value = case priority_value_result {
    Ok(p) -> p
    Error(_) -> Medium
  }

  // Handle completed field (we don't validate it, just use default if not provided)
  let _completed = case completed_result {
    Ok(c) -> c
    Error(_) -> False
  }

  case errors {
    [] -> {
      // All validations passed, construct TodoAttrs
      let assert Ok(title) = title_result
      Ok(TodoAttrs(title: title, description: description_opt, priority: priority_value))
    }
    _ -> Error(errors)
  }
}

// Extract a required string field from JSON
fn extract_string_field(json: String, field: String) -> Result(String, Nil) {
  let pattern = "\"" <> field <> "\":"
  case string.split(json, pattern) {
    [_, rest] -> {
      let rest = string.trim_start(rest)
      case rest {
        "\"" <> quoted -> {
          case string.split(quoted, "\"") {
            [value, ..] -> Ok(value)
            _ -> Error(Nil)
          }
        }
        _ -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

// Extract an optional string field (handles null or missing)
fn extract_optional_string_field(json: String, field: String) -> Option(String) {
  let pattern = "\"" <> field <> "\":"
  case string.split(json, pattern) {
    [_, rest] -> {
      let rest = string.trim_start(rest)
      case rest {
        "null" <> _ -> None
        "\"" <> quoted -> {
          case string.split(quoted, "\"") {
            [value, ..] -> Some(value)
            _ -> None
          }
        }
        _ -> None
      }
    }
    _ -> None
  }
}

// Extract an optional boolean field
fn extract_optional_bool_field(json: String, field: String) -> Result(Bool, Nil) {
  let pattern = "\"" <> field <> "\":"
  case string.split(json, pattern) {
    [_, rest] -> {
      let rest = string.trim_start(rest)
      case rest {
        "true" <> _ -> Ok(True)
        "false" <> _ -> Ok(False)
        _ -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

// Encode validation errors to JSON string
fn encode_validation_errors(errors: List(ErrorField)) -> String {
  let error_objects = list.map(errors, fn(e) {
    json.object([
      #("field", json.string(e.field)),
      #("message", json.string(e.message)),
    ])
  })

  json.object([#("errors", json.array(error_objects, fn(x) { x }))])
  |> json.to_string
}

fn not_found() -> Response {
  server.json_response(
    404,
    json.object([#("error", json.string("Not found"))])
    |> json.to_string,
  )
}
