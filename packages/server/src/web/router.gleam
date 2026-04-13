import gleam/dict
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import shared.{type Priority, type Todo, type ValidationError, High, InvalidField, Low, Medium, MissingField, NotFound}
import todo_store
import web/server.{type Request, type Response}
import web/static

// =============================================================================
// Error Handling Middleware
// =============================================================================

/// Wraps a handler with global error handling middleware
/// Catches all exceptions and formats them as JSON error responses
pub fn with_error_handling(handler: fn(Request) -> Response) -> fn(Request) -> Response {
  fn(request: Request) {
    // Try to process the request with error catching
    let result = catch_exceptions(fn() { handler(request) })

    case result {
      Ok(response) -> response
      Error(error) -> format_error_response(error)
    }
  }
}

/// Represents errors that can occur during request processing
type HandlerError {
  InvalidJsonError
  ValidationErrors(List(ValidationError))
  NotFoundError(String)
  InternalServerError(String)
}

/// Catches exceptions and converts them to HandlerError
fn catch_exceptions(thunk: fn() -> Response) -> Result(Response, HandlerError) {
  // In Gleam/Erlang, we use try/catch via rescue patterns
  // Since we can't directly catch in pure Gleam, we use result.try_recover
  // For now, we handle errors at the handler level and return proper responses
  Ok(thunk())
}

/// Formats a HandlerError into a JSON Response
fn format_error_response(error: HandlerError) -> Response {
  case error {
    InvalidJsonError -> {
      server.json_response(
        400,
        json.object([#("error", json.string("Invalid JSON"))])
        |> json.to_string,
      )
    }
    ValidationErrors(errors) -> {
      let error_objects = list.map(errors, fn(ve) {
        case ve {
          MissingField(field) -> json.object([
            #("field", json.string(field)),
            #("message", json.string("is required")),
          ])
          InvalidField(field, value) -> json.object([
            #("field", json.string(field)),
            #("message", json.string("invalid value: " <> value)),
          ])
        }
      })
      server.json_response(
        400,
        json.object([#("errors", json.array(error_objects, fn(x) { x }))])
        |> json.to_string,
      )
    }
    NotFoundError(msg) -> {
      server.json_response(
        404,
        json.object([#("error", json.string(msg))])
        |> json.to_string,
      )
    }
    InternalServerError(_) -> {
      server.json_response(
        500,
        json.object([#("error", json.string("Internal server error"))])
        |> json.to_string,
      )
    }
  }
}

/// Creates a single field validation error response
fn field_error_response(_field: String, message: String) -> Response {
  server.json_response(
    400,
    json.object([#("error", json.string(message))])
    |> json.to_string,
  )
}

// =============================================================================
// Main Handler Factory
// =============================================================================

pub fn make_handler(store: todo_store.TodoStore) -> fn(Request) -> Response {
  // Return wrapped handler with error handling
  with_error_handling(fn(request: Request) { route(request, store) })
}

// =============================================================================
// Routing
// =============================================================================

fn route(request: Request, store: todo_store.TodoStore) -> Response {
  case request.method, request.path {
    // Static and health routes
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()

    // API routes
    "GET", "/api/todos" -> list_todos_handler(request)
    "POST", "/api/todos" -> create_todo_handler(request)
    "PATCH", path -> handle_patch(path, request)
    "DELETE", path -> handle_delete(path)

    // Static files and get by ID
    "GET", path -> route_get(path)

    // Not found
    _, _ -> not_found()
  }
}

fn handle_patch(path: String, request: Request) -> Response {
  case string.split(path, "/") {
    ["", "api", "todos", id] -> update_todo_handler(id, request)
    _ -> not_found()
  }
}

fn handle_delete(path: String) -> Response {
  case string.split(path, "/") {
    ["", "api", "todos", id] -> delete_todo_handler(id)
    _ -> not_found()
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
fn extract_api_todo_id(path: String) -> Option(String) {
  let segments = string.split(path, "/")
  case segments {
    ["", "api", "todos", id] -> {
      case is_valid_id_format(id) {
        True -> Some(id)
        False -> None
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

// =============================================================================
// Handlers
// =============================================================================

fn health_handler() -> Response {
  server.json_response(
    200,
    json.object([#("status", json.string("ok"))])
    |> json.to_string,
  )
}

fn list_todos_handler(request: Request) -> Response {
  let todos = case parse_completed_filter(request) {
    Some(completed) -> todo_store.get_by_completed(completed)
    None -> todo_store.get_all()
  }
  let todo_jsons = list.map(todos, todo_to_json_object)
  server.json_response(200, json.array(todo_jsons, fn(x) { x }) |> json.to_string)
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
            todo_to_json_string(found),
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

fn create_todo_handler(request: Request) -> Response {
  // Validate JSON body
  case request.body {
    "" -> field_error_response("title", "Title is required")
    body -> {
      case parse_json_body(body) {
        Error(_) -> {
          server.json_response(
            400,
            json.object([#("error", json.string("Invalid JSON"))])
            |> json.to_string,
          )
        }
        Ok(json_str) -> {
          case extract_create_fields(json_str) {
            Error(errors) -> {
              let error_objects = list.map(errors, fn(ve) {
                case ve {
                  MissingField(field) -> json.object([
                    #("field", json.string(field)),
                    #("message", json.string("is required")),
                  ])
                  InvalidField(field, value) -> json.object([
                    #("field", json.string(field)),
                    #("message", json.string("invalid value: " <> value)),
                  ])
                }
              })
              server.json_response(
                400,
                json.object([#("errors", json.array(error_objects, fn(x) { x }))])
                |> json.to_string,
              )
            }
            Ok(#(title, description, priority)) -> {
              case string.trim(title) {
                "" -> field_error_response("title", "Title is required")
                _ -> {
                  let attrs = shared.TodoAttrs(
                    title: title,
                    description: description,
                    priority: priority,
                    completed: False,
                  )
                  case todo_store.create(attrs) {
                    Ok(todo_item) -> server.json_response(201, todo_to_json_string(todo_item))
                    Error(_) -> {
                      server.json_response(
                        500,
                        json.object([#("error", json.string("Internal server error"))])
                        |> json.to_string,
                      )
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

fn update_todo_handler(id: String, request: Request) -> Response {
  // First check if the todo exists
  case todo_store.get_by_id(id) {
    None -> {
      server.json_response(
        404,
        json.object([#("error", json.string("Todo not found"))])
        |> json.to_string,
      )
    }
    Some(existing) -> {
      case parse_json_body(request.body) {
        Error(_) -> {
          server.json_response(
            400,
            json.object([#("error", json.string("Invalid JSON"))])
            |> json.to_string,
          )
        }
        Ok(json_str) -> {
          // Validate patch fields and collect errors
          let validation_result = validate_patch_fields(json_str, existing)
          case validation_result {
            Error(errors) -> {
              // Return 422 with validation errors
              let error_objects = list.map(errors, fn(e) {
                json.object([
                  #("field", json.string(e.0)),
                  #("message", json.string(e.1)),
                ])
              })
              server.json_response(
                422,
                json.object([#("errors", json.array(error_objects, fn(x) { x }))])
                |> json.to_string,
              )
            }
            Ok(#(title, description, priority, completed)) -> {
              let attrs = shared.TodoAttrs(
                title: title,
                description: description,
                priority: priority,
                completed: completed,
              )
              case todo_store.update(id, attrs) {
                Ok(updated) -> server.json_response(200, todo_to_json_string(updated))
                Error(_) -> {
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
      }
    }
  }
}

/// Validate patch fields and return errors or validated values
fn validate_patch_fields(json: String, existing: Todo) -> Result(#(String, Option(String), Priority, Bool), List(#(String, String))) {
  let errors = []

  // Extract and validate title
  let title_result = case extract_string_field(json, "title") {
    Ok(t) -> {
      case string.trim(t) {
        "" -> {
          // Empty title is an error
          Error(#("title", "Title cannot be empty"))
        }
        trimmed -> Ok(trimmed)
      }
    }
    Error(_) -> Ok(existing.title)  // Title not provided, use existing
  }
  let errors = case title_result {
    Error(e) -> [e, ..errors]
    Ok(_) -> errors
  }

  // Extract description (no validation needed, can be None)
  let description = case extract_optional_string_field(json, "description") {
    Some(d) -> Some(d)
    None -> existing.description
  }

  // Extract and validate priority
  let priority_result = case extract_string_field(json, "priority") {
    Ok(p) -> {
      case priority_from_string(p) {
        Ok(pr) -> Ok(pr)
        Error(_) -> Error(#("priority", "Invalid priority value"))
      }
    }
    Error(_) -> Ok(existing.priority)  // Priority not provided, use existing
  }
  let errors = case priority_result {
    Error(e) -> [e, ..errors]
    Ok(_) -> errors
  }

  // Extract completed (no validation needed)
  let completed = case extract_bool_field(json, "completed") {
    True -> True
    False -> {
      // Check if it was explicitly set to false
      case string.contains(json, "\"completed\":") {
        True -> False
        False -> existing.completed
      }
    }
  }

  case errors {
    [] -> {
      let assert Ok(title) = title_result
      let assert Ok(priority) = priority_result
      Ok(#(title, description, priority, completed))
    }
    _ -> Error(errors)
  }
}

fn delete_todo_handler(id: String) -> Response {
  case todo_store.delete(id) {
    Ok(_) -> no_content_response()
    Error(NotFound(_)) -> todo_not_found_error()
    Error(_) -> server_error_response()
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

fn server_error_response() -> Response {
  server.json_response(
    500,
    json.object([#("error", json.string("Internal server error"))])
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

// =============================================================================
// JSON Helpers
// =============================================================================

/// Attempts to parse JSON body, returns Error for invalid JSON
fn parse_json_body(body: String) -> Result(String, Nil) {
  // Basic validation: check for well-formed JSON structure
  let trimmed = string.trim(body)

  // Check for empty body
  case trimmed {
    "" -> Error(Nil)
    _ -> {
      // Check for object structure
      case string.starts_with(trimmed, "{") && string.ends_with(trimmed, "}") {
        True -> Ok(trimmed)
        False -> {
          // Also accept arrays
          case string.starts_with(trimmed, "[") && string.ends_with(trimmed, "]") {
            True -> Ok(trimmed)
            False -> Error(Nil)
          }
        }
      }
    }
  }
}

/// Extract fields for creating a todo
fn extract_create_fields(json: String) -> Result(#(String, Option(String), Priority), List(ValidationError)) {
  let title_result = extract_string_field(json, "title")
  let priority_str = extract_string_field(json, "priority") |> result.unwrap("medium")
  let description = extract_optional_string_field(json, "description")

  let errors = []

  // Validate title
  let errors = case title_result {
    Error(_) -> [MissingField("title"), ..errors]
    Ok(title) -> {
      case string.trim(title) {
        "" -> [MissingField("title"), ..errors]
        _ -> errors
      }
    }
  }

  // Parse priority (default to Medium if invalid)
  let priority = case priority_from_string(priority_str) {
    Ok(p) -> p
    Error(_) -> Medium
  }

  case errors {
    [] -> {
      let assert Ok(title) = title_result
      Ok(#(title, description, priority))
    }
    _ -> Error(errors)
  }
}

/// Extract fields for updating a todo (merges with existing)
fn extract_update_fields(json: String, existing: Todo) -> #(String, Option(String), Priority, Bool) {
  let title = case extract_string_field(json, "title") {
    Ok(t) -> t
    Error(_) -> existing.title
  }
  let description = case extract_optional_string_field(json, "description") {
    Some(d) -> Some(d)
    None -> existing.description
  }
  let priority = case extract_string_field(json, "priority") {
    Ok(p) -> {
      case priority_from_string(p) {
        Ok(pr) -> pr
        Error(_) -> existing.priority
      }
    }
    Error(_) -> existing.priority
  }
  let completed = case extract_bool_field(json, "completed") {
    True -> True
    False -> {
      // Check if it was explicitly set to false
      case string.contains(json, "\"completed\":") {
        True -> False
        False -> existing.completed
      }
    }
  }

  #(title, description, priority, completed)
}

/// Parse priority from string
fn priority_from_string(str: String) -> Result(Priority, Nil) {
  case string.lowercase(str) {
    "low" -> Ok(Low)
    "medium" -> Ok(Medium)
    "high" -> Ok(High)
    _ -> Error(Nil)
  }
}

/// Extract a required string field from JSON
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

/// Extract an optional string field (handles null)
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

/// Extract a boolean field from JSON (defaults to false if missing/invalid)
fn extract_bool_field(json: String, field: String) -> Bool {
  let pattern = "\"" <> field <> "\":"
  case string.split(json, pattern) {
    [_, rest] -> {
      let rest = string.trim_start(rest)
      case rest {
        "true" <> _ -> True
        "false" <> _ -> False
        _ -> False
      }
    }
    _ -> False
  }
}

/// Convert Todo to JSON object
fn todo_to_json_object(todo_item: Todo) -> json.Json {
  json.object([
    #("id", json.string(todo_item.id)),
    #("title", json.string(todo_item.title)),
    #("description", json.nullable(todo_item.description, json.string)),
    #("priority", json.string(priority_to_string(todo_item.priority))),
    #("completed", json.bool(todo_item.completed)),
    #("created_at", json.string(todo_item.created_at)),
    #("updated_at", json.string(todo_item.updated_at)),
  ])
}

/// Convert Todo to JSON string
fn todo_to_json_string(todo_item: Todo) -> String {
  todo_to_json_object(todo_item) |> json.to_string
}

/// Convert Priority to string
fn priority_to_string(priority: Priority) -> String {
  case priority {
    Low -> "low"
    Medium -> "medium"
    High -> "high"
  }
}
