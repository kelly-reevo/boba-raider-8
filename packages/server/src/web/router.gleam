import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/string
import shared
import todo_store.{type Store}
import web/server.{type Request, type Response, json_response}

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
  // Match API paths first
  case request.method, request.path {
    "GET", "/" -> static_serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    // Todo API endpoints
    "POST", "/api/todos" -> create_todo_handler(request)
    _, _ -> route_with_path_check(request.method, request.path)
  }
}

fn route_with_path_check(method: String, path: String) -> Response {
  // Check for GET /api/todos/:id
  case method, string.starts_with(path, "/api/todos/") {
    "GET", True -> get_todo_handler(path)
    _, _ -> not_found()
  }
}

fn static_serve_index() -> Response {
  server.html_response(200, "<html><body>Hello</body></html>")
}

fn health_handler() -> Response {
  json_response(
    200,
    json.object([#("status", json.string("ok"))])
    |> json.to_string,
  )
}

fn not_found() -> Response {
  json_response(
    404,
    json.object([#("error", json.string("Not found"))])
    |> json.to_string,
  )
}

fn todo_not_found() -> Response {
  json_response(
    404,
    json.object([#("error", json.string("todo not found"))])
    |> json.to_string,
  )
}

fn bad_request(msg: String) -> Response {
  json_response(
    400,
    json.object([#("error", json.string(msg))])
    |> json.to_string,
  )
}

fn internal_error() -> Response {
  json_response(
    500,
    json.object([#("error", json.string("Internal server error"))])
    |> json.to_string,
  )
}

// ============================================================================
// Todo API Handlers
// ============================================================================

/// POST /api/todos - Create a new todo
fn create_todo_handler(request: Request) -> Response {
  case get_store() {
    None -> internal_error()
    Some(store) -> {
      // Parse request body
      let result = parse_create_input(request.body)

      case result {
        Error(msg) -> bad_request(msg)
        Ok(#(title, description)) -> {
          case todo_store.create_todo(store, title, description) {
            Error(err) -> bad_request(err)
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

/// GET /api/todos/:id - Get a single todo by ID
fn get_todo_handler(path: String) -> Response {
  // Extract id from path: /api/todos/:id
  // Remove "/api/todos/" prefix (11 characters)
  let prefix_length = 11
  let id = case string.length(path) > prefix_length {
    True -> string.slice(path, prefix_length, string.length(path) - prefix_length)
    False -> ""
  }

  // Handle empty id
  case string.is_empty(id) {
    True -> todo_not_found()
    False -> {
      case get_store() {
        None -> internal_error()
        Some(store) -> {
          case todo_store.get_todo(store, id) {
            None -> todo_not_found()
            Some(found) -> {
              let json_body = todo_to_response_json(found) |> json.to_string
              json_response(200, json_body)
            }
          }
        }
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
