import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import models/todo_item.{type Todo}
import todo_store.{type TodoStore}
import web/server.{type Request, type Response}
import web/static

/// Validation error type
pub type ValidationError {
  ValidationError(field: String, message: String)
}

/// Request body for creating a todo
type CreateTodoRequest {
  CreateTodoRequest(
    title: String,
    description: Option(String),
    priority: String,
    completed: Bool,
  )
}

/// Make handler that includes store dependency
pub fn make_handler(store: TodoStore) -> fn(Request) -> Response {
  fn(request: Request) { route(request, store) }
}

fn route(request: Request, store: TodoStore) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "POST", "/api/todos" -> create_todo_handler(request, store)
    "GET", path -> route_get(path, store)
    _, _ -> not_found()
  }
}

fn route_get(path: String, store: TodoStore) -> Response {
  case string.starts_with(path, "/static/") {
    True -> static.serve(path)
    False -> route_api_get(path, store)
  }
}

fn route_api_get(path: String, store: TodoStore) -> Response {
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
        "" -> None
        _ -> Some(id)
      }
    }
    False -> None
  }
}

/// Handle GET /api/todos/:id
fn handle_get_todo(id: String, store: TodoStore) -> Response {
  // Validate UUID format
  case is_valid_uuid(id) {
    False -> bad_request_or_not_found()
    True -> {
      case todo_store.read(store, id) {
        Ok(found_todo) -> json_response(200, encode_todo(found_todo) |> json.to_string())
        Error(_) -> not_found_with_message("Todo not found")
      }
    }
  }
}

/// POST /api/todos handler
fn create_todo_handler(request: Request, store: TodoStore) -> Response {
  // Check if body is empty first
  case request.body {
    "" -> {
      server.json_response(
        400,
        json.object([#("error", json.string("Invalid JSON: could not parse request body"))])
        |> json.to_string,
      )
    }
    _ -> {
      // Try to decode as an object first to verify it's a valid JSON object
      case json.parse(from: request.body, using: decode.dict(decode.string, decode.dynamic)) {
        Ok(_) -> {
          // It's a valid JSON object, now try to decode with our schema
          case json.parse(from: request.body, using: create_request_decoder()) {
            Ok(req) -> {
              // Successfully decoded, now validate
              case validate_create_request(req) {
                [] -> {
                  // No validation errors, create the todo
                  let description = case req.description {
                    Some(d) -> d
                    None -> ""
                  }
                  case todo_store.create(store, req.title, description, req.priority) {
                    Ok(created_todo) -> {
                      // Return 201 with created todo
                      server.json_response(
                        201,
                        encode_todo(created_todo) |> json.to_string,
                      )
                    }
                    Error(_) -> {
                      server.json_response(
                        500,
                        json.object([#("error", json.string("Failed to create todo"))])
                        |> json.to_string,
                      )
                    }
                  }
                }
                errors -> {
                  // Return 422 with validation errors
                  server.json_response(
                    422,
                    encode_validation_errors(errors) |> json.to_string,
                  )
                }
              }
            }
            Error(_) -> {
              // Valid JSON object but wrong field types
              server.json_response(
                422,
                json.object([#("errors", json.array(
                  [ValidationError("body", "Invalid request field types")],
                  fn(e) {
                    json.object([
                      #("field", json.string(e.field)),
                      #("message", json.string(e.message)),
                    ])
                  }
                ))])
                |> json.to_string,
              )
            }
          }
        }
        Error(_) -> {
          // Not a valid JSON object (could be array, string, number, or malformed)
          server.json_response(
            400,
            json.object([#("error", json.string("Invalid JSON: could not parse request body"))])
            |> json.to_string,
          )
        }
      }
    }
  }
}

/// Decoder for create todo request body
/// Returns defaults for missing fields: title="", description=None, priority="medium", completed=False
fn create_request_decoder() -> decode.Decoder(CreateTodoRequest) {
  // Use field with optional decoders - optional returns None for null/missing
  // For required fields we still want to handle gracefully, so use optional_field
  use title <- decode.optional_field("title", "", decode.string)
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use priority <- decode.optional_field("priority", "medium", decode.string)
  use completed <- decode.optional_field("completed", False, decode.bool)

  decode.success(CreateTodoRequest(
    title: title,
    description: description,
    priority: priority,
    completed: completed,
  ))
}

/// Validate create request
fn validate_create_request(req: CreateTodoRequest) -> List(ValidationError) {
  let errors = []

  // Validate title (required, non-empty)
  let errors = case string.trim(req.title) {
    "" -> [ValidationError("title", "Title is required"), ..errors]
    _ -> errors
  }

  // Validate priority (must be low, medium, or high)
  let errors = case req.priority {
    "low" -> errors
    "medium" -> errors
    "high" -> errors
    "" -> errors  // Default will be applied, considered valid
    _ -> [ValidationError("priority", "Priority must be one of: low, medium, high"), ..errors]
  }

  list.reverse(errors)
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

/// Encode todo to JSON
fn encode_todo(t: todo_item.Todo) -> json.Json {
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
    #("updated_at", json.string(t.created_at)),
  ])
}

/// Encode validation errors to JSON
fn encode_validation_errors(errors: List(ValidationError)) -> json.Json {
  json.object([
    #("errors", json.array(errors, fn(e) {
      json.object([
        #("field", json.string(e.field)),
        #("message", json.string(e.message)),
      ])
    })),
  ])
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
