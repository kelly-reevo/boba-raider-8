import gleam/dict
import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/string
import shared
import todo_store.{type Store}
import web/server.{type Request, type Response, json_response}
import web/static

// Store reference (using a mutable reference pattern)
// For simplicity, we use an ETS table entry that can be looked up

/// Configure the router with a store instance
/// Called during app startup or test setup
pub fn configure(store: Store) -> fn(Request) -> Response {
  // Store in ETS using FFI
  ffi_configure(store)
  handle_request
}

/// Get the currently configured store
fn get_store() -> Option(Store) {
  ffi_get_store()
}

// FFI for store registry
@external(erlang, "router_ffi", "configure")
fn ffi_configure(store: Store) -> Nil

@external(erlang, "router_ffi", "get_store")
fn ffi_get_store() -> Option(Store)

/// Main entry point for handling requests
/// Exported for both production use and test access
pub fn handle_request(request: Request) -> Response {
  route(request)
}

fn route(request: Request) -> Response {
  // Wrap all routes with error handling
  wrap_with_error_handling(fn() {
    // Match API paths first
    case request.method, request.path {
      "GET", "/" -> static.serve_index()
      "GET", "/health" -> health_handler()
      "GET", "/api/health" -> health_handler()

      // Todo API endpoints
      "GET", "/api/todos" -> list_todos_handler()
      "GET", "/api/todos/trigger-error" -> trigger_error_handler()
      "GET", "/api/todos/" <> id -> get_todo_handler(id)
      "POST", "/api/todos" -> create_todo_handler(request)
      "PATCH", "/api/todos/" <> id -> update_todo_handler(request, id)
      "DELETE", "/api/todos/" <> id -> delete_todo_handler(id)

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
  json_response(
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
fn list_todos_handler() -> Response {
  case get_store() {
    None -> internal_error()
    Some(store) -> {
      let todos = todo_store.get_all_todos(store)
      let todos_json = json.array(todos, todo_to_response_json)
      json_response(200, todos_json |> json.to_string)
    }
  }
}

/// Get a single todo by ID
fn get_todo_handler(id: String) -> Response {
  case get_store() {
    None -> internal_error()
    Some(store) -> {
      case todo_store.get_todo(store, id) {
        None -> not_found_error()
        Some(found) -> {
          let json_body = todo_to_response_json(found) |> json.to_string
          json_response(200, json_body)
        }
      }
    }
  }
}

/// POST /api/todos - Create a new todo
fn create_todo_handler(request: Request) -> Response {
  case get_store() {
    None -> internal_error()
    Some(store) -> {
      // Parse request body
      let result = parse_create_input(request.body)

      case result {
        Error(msg) -> bad_request_error(msg)
        Ok(#(title, description)) -> {
          case todo_store.create_todo(store, title, description) {
            Error(err) -> bad_request_error(err)
            Ok(created) -> {
              let json_body = shared.todo_to_json(created) |> json.to_string
              json_response(201, json_body)
            }
          }
        }
      }
    }
  }
}

/// Parse create todo input from JSON
fn parse_create_input(body: String) -> Result(#(String, String), String) {
  // Decode the title (required)
  let title_decoder = {
    use title <- decode.field("title", decode.string)
    decode.success(title)
  }

  // Decode the description (optional)
  let desc_decoder = {
    use desc <- decode.optional_field("description", "", decode.string)
    decode.success(desc)
  }

  let title_result = json.parse(body, title_decoder)
  let desc_result = json.parse(body, desc_decoder)

  case title_result {
    Error(_) -> Error("Invalid JSON: missing or invalid title")
    Ok(title) -> {
      let trimmed = string.trim(title)
      case string.is_empty(trimmed) {
        True -> Error("Title is required")
        False -> {
          let description = case desc_result {
            Ok(d) -> d
            Error(_) -> ""
          }
          Ok(#(trimmed, description))
        }
      }
    }
  }
}

/// Update an existing todo
fn update_todo_handler(request: Request, id: String) -> Response {
  case get_store() {
    None -> internal_error()
    Some(store) -> {
      // Parse the update input
      case parse_update_input(request.body) {
        Error(msg) -> bad_request_error(msg)
        Ok(input) -> {
          case todo_store.update_todo(store, id, input) {
            Error(_) -> not_found_error()
            Ok(updated) -> {
              let json_body = shared.todo_to_json(updated) |> json.to_string
              json_response(200, json_body)
            }
          }
        }
      }
    }
  }
}

/// Parse update todo input from JSON
fn parse_update_input(body: String) -> Result(shared.UpdateTodoInput, String) {
  let decoder = {
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
    decode.success(shared.UpdateTodoInput(title:, description:, completed:))
  }

  case json.parse(body, decoder) {
    Ok(input) -> Ok(input)
    Error(_) -> Error("Invalid JSON")
  }
}

/// Delete a todo
fn delete_todo_handler(id: String) -> Response {
  case get_store() {
    None -> internal_error()
    Some(store) -> {
      case todo_store.delete_todo(store, id) {
        Error(_) -> not_found_error()
        Ok(_) -> server.json_response(204, "")
      }
    }
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
  ])
}
