import gleam/dict
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/string
import gleam/dynamic/decode
import shared
import todo_store.{type Store}
import web/server.{type Request, type Response}
import web/static

/// Make handler with store for production use
/// The store is passed explicitly to each handler
pub fn make_handler(store: Store) -> fn(Request) -> Response {
  fn(request: Request) { route(request, store) }
}

fn route(request: Request, store: Store) -> Response {
  // Wrap all routes with error handling
  wrap_with_error_handling(fn() {
    case request.method, request.path {
      "GET", "/" -> static.serve_index()
      "GET", "/health" -> health_handler()
      "GET", "/api/health" -> health_handler()

      // TODO API endpoints
      "GET", "/api/todos" -> list_todos_handler(store)
      "GET", "/api/todos/trigger-error" -> trigger_error_handler()
      "GET", "/api/todos/" <> id -> get_todo_handler(id, store)
      "POST", "/api/todos" -> create_todo_handler(request, store)
      "PATCH", "/api/todos/" <> id -> update_todo_handler(request, id, store)
      "DELETE", "/api/todos/" <> id -> delete_todo_handler(id, store)

      "GET", path -> route_get(path)
      _, _ -> not_found_error()
    }
  })
}

fn route_get(path: String) -> Response {
  case string.starts_with(path, "/static/") {
    True -> static.serve(path)
    False -> not_found_error()
  }
}

// ============================================================================
// Error Response Helpers - Standardized format: {error: string}
// ============================================================================

/// Standard 400 Bad Request error
fn bad_request_error(message: String) -> Response {
  error_response(400, message)
}

/// Standard 404 Not Found error
fn not_found_error() -> Response {
  error_response(404, "Not found")
}

/// Standard 500 Internal Server Error - generic message, no stack traces
fn internal_error() -> Response {
  error_response(500, "Internal server error")
}

/// Generic error response builder - all errors follow {error: string} format
fn error_response(status: Int, message: String) -> Response {
  server.json_response(
    status,
    json.object([#("error", json.string(message))])
    |> json.to_string,
  )
}

// ============================================================================
// Error Handling Middleware
// ============================================================================

/// Wraps route handlers with consistent error handling
/// - Returns safe error responses (no stack traces leaked)
/// - Ensures consistent JSON format for all errors
fn wrap_with_error_handling(handler: fn() -> Response) -> Response {
  // Execute handler and catch any Erlang exceptions via FFI
  execute_safely(handler)
}

/// Execute handler safely, returning 500 for any errors
fn execute_safely(handler: fn() -> Response) -> Response {
  // Use FFI to safely execute the handler
  case ffi_execute_with_catch(handler) {
    Ok(response) -> response
    Error(_) -> internal_error()
  }
}

/// FFI function to execute handler with catch - prevents stack traces leaking
@external(erlang, "router_ffi", "execute_with_catch")
fn ffi_execute_with_catch(handler: fn() -> Response) -> Result(Response, Nil)

// ============================================================================
// Handlers
// ============================================================================

fn health_handler() -> Response {
  server.json_response(
    200,
    json.object([#("status", json.string("ok"))])
    |> json.to_string,
  )
}

/// Trigger an internal error for testing 500 responses
fn trigger_error_handler() -> Response {
  // Intentionally cause a crash to test error handling
  let crash = case dict.get(dict.new(), "nonexistent") {
    Ok(value) -> value
    Error(_) -> panic as "Intentional test error"
  }

  // This line never executes due to panic
  let _ = crash
  server.json_response(200, "{}")
}

/// List all todos
fn list_todos_handler(store: Store) -> Response {
  let todos = todo_store.get_all_todos(store)
  let todos_json = json.array(todos, todo_to_response_json)
  server.json_response(200, todos_json |> json.to_string)
}

/// Get a single todo by ID
fn get_todo_handler(id: String, store: Store) -> Response {
  case todo_store.get_todo(store, id) {
    None -> not_found_error()
    Some(found) -> {
      let json_body = todo_to_response_json(found) |> json.to_string
      server.json_response(200, json_body)
    }
  }
}

// Decoder for create todo request body
type CreateTodoRequest {
  CreateTodoRequest(title: String, description: String)
}

fn create_todo_decoder() -> decode.Decoder(CreateTodoRequest) {
  use title <- decode.field("title", decode.string)
  use description <- decode.optional_field(
    "description",
    "",
    decode.string,
  )
  decode.success(CreateTodoRequest(title:, description:))
}

/// POST /api/todos - Create a new todo
fn create_todo_handler(request: Request, store: Store) -> Response {
  // Parse the JSON body
  let parse_result = json.parse(request.body, create_todo_decoder())

  case parse_result {
    // Successfully parsed JSON
    Ok(parsed) -> {
      let trimmed_title = string.trim(parsed.title)

      // Validate title is not empty
      case string.is_empty(trimmed_title) {
        True -> {
          bad_request_error("Title is required")
        }
        False -> {
          // Validate title length (max 200 chars)
          case string.length(trimmed_title) > 200 {
            True -> {
              bad_request_error("Title is too long")
            }
            False -> {
              // Create the todo in the store
              case todo_store.create_todo(store, trimmed_title, parsed.description) {
                Ok(created_todo) -> {
                  // Return 201 with created todo JSON
                  server.json_response(
                    201,
                    shared.todo_to_json(created_todo) |> json.to_string,
                  )
                }
                Error(msg) -> {
                  bad_request_error(msg)
                }
              }
            }
          }
        }
      }
    }

    // Failed to parse JSON
    Error(_) -> {
      bad_request_error("Title is required")
    }
  }
}

// Decoder for update todo request body
type UpdateTodoRequest {
  UpdateTodoRequest(
    title: Option(String),
    description: Option(String),
    completed: Option(Bool),
  )
}

fn update_todo_decoder() -> decode.Decoder(UpdateTodoRequest) {
  use title <- decode.optional_field("title", None, decode.optional(decode.string))
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use completed <- decode.optional_field(
    "completed",
    None,
    decode.optional(decode.bool),
  )
  decode.success(UpdateTodoRequest(title:, description:, completed:))
}

/// Update an existing todo
fn update_todo_handler(request: Request, id: String, store: Store) -> Response {
  // Parse the update input
  case json.parse(request.body, update_todo_decoder()) {
    Ok(input) -> {
      // Validate title if provided
      case input.title {
        Some(title) -> {
          let trimmed = string.trim(title)
          case string.is_empty(trimmed) {
            True -> bad_request_error("Title cannot be empty")
            False -> {
              case string.length(trimmed) > 200 {
                True -> bad_request_error("Title is too long")
                False -> do_update(id, store, Some(trimmed), input.description, input.completed)
              }
            }
          }
        }
        None -> do_update(id, store, None, input.description, input.completed)
      }
    }
    Error(_) -> bad_request_error("Invalid JSON")
  }
}

fn do_update(
  id: String,
  store: Store,
  title: Option(String),
  description: Option(String),
  completed: Option(Bool),
) -> Response {
  let input = shared.UpdateTodoInput(title:, description:, completed:)
  case todo_store.update_todo(store, id, input) {
    Error(_) -> not_found_error()
    Ok(updated) -> {
      let json_body = shared.todo_to_json(updated) |> json.to_string
      server.json_response(200, json_body)
    }
  }
}

/// Delete a todo
fn delete_todo_handler(id: String, store: Store) -> Response {
  case todo_store.delete_todo(store, id) {
    Error(_) -> not_found_error()
    Ok(_) -> server.json_response(204, "")
  }
}

/// Convert Todo to JSON response per boundary contract:
/// {id: string, title: string, description: string|null, completed: bool}
fn todo_to_response_json(item: shared.Todo) -> json.Json {
  json.object([
    #("id", json.string(item.id)),
    #("title", json.string(item.title)),
    #("description", case string.is_empty(item.description) {
      True -> json.null()
      False -> json.string(item.description)
    }),
    #("completed", json.bool(item.completed)),
    #("created_at", json.int(item.created_at)),
    #("updated_at", json.int(item.updated_at)),
  ])
}
