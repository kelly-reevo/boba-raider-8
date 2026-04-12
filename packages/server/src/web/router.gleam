import gleam/dict
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import shared.{type Todo}
import todo_store.{
  type Store,
  CreateOkResult, CreateErrorResult, ValidationErrorCreate,
  GetOkResult, GetErrorResult, NotFoundGet,
  UpdateOkResult, UpdateErrorResult, NotFoundUpdate, ValidationErrorUpdate,
  DeleteOkResult, DeleteErrorResult, NotFoundDelete,
}
import web/server.{type Request, type Response}
import web/static

// Error response types per boundary contract
pub type FieldError {
  FieldError(field: String, message: String)
}

pub type ErrorResponse {
  SimpleError(error: String)
  ValidationErrors(errors: List(FieldError))
}

/// Main handler factory - creates handler with store dependency
pub fn make_handler(store: Store) -> fn(Request) -> Response {
  fn(request: Request) { handle_request(request, store) }
}

/// Main request handler with error handling middleware
fn handle_request(request: Request, store: Store) -> Response {
  // Wrap all request handling in catch for 500 errors
  let response = case catch_errors(fn() { route(request, store) }) {
    Ok(response) -> response
    Error(error_msg) -> server_error_response(error_msg)
  }

  // Add CORS headers to all responses
  add_cors_headers(response)
}

/// Route requests to appropriate handlers
fn route(request: Request, store: Store) -> Response {
  // First check exact matches
  case request.method, request.path {
    // Health check
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()

    // Static files
    "GET", "/" -> static.serve_index()

    // CORS preflight for API routes
    "OPTIONS", "/api/todos" -> cors_preflight_response()
    "OPTIONS", path -> route_options_preflight(path)

    // Todo API routes - exact matches
    "GET", "/api/todos" -> list_todos_handler(store, request)
    "POST", "/api/todos" -> create_todo_handler(store, request)

    // Todo API routes - with ID (route to handler by method)
    "GET", path -> route_get_with_path(path, store, request)
    "POST", path -> route_post_with_path(path, store, request)
    "PATCH", path -> route_patch_with_path(path, store, request)
    "DELETE", path -> route_delete_with_path(path, store)

    // 404 for everything else
    _, _ -> not_found_response()
  }
}

/// Handle GET requests that might have paths
fn route_get_with_path(path: String, store: Store, _request: Request) -> Response {
  case string.starts_with(path, "/api/todos/") {
    True -> {
      let id = string.drop_start(path, 11)
      get_todo_handler(store, id)
    }
    False -> {
      case string.starts_with(path, "/static/") {
        True -> static.serve(path)
        False -> not_found_response()
      }
    }
  }
}

/// Handle POST requests with paths
fn route_post_with_path(path: String, store: Store, request: Request) -> Response {
  case path {
    "/api/todos" -> create_todo_handler(store, request)
    _ -> not_found_response()
  }
}

/// Handle PATCH requests with IDs
fn route_patch_with_path(path: String, store: Store, request: Request) -> Response {
  case string.starts_with(path, "/api/todos/") {
    True -> {
      let id = string.drop_start(path, 11)
      update_todo_handler(store, id, request)
    }
    False -> not_found_response()
  }
}

/// Handle DELETE requests with IDs
fn route_delete_with_path(path: String, store: Store) -> Response {
  case string.starts_with(path, "/api/todos/") {
    True -> {
      let id = string.drop_start(path, 11)
      delete_todo_handler(store, id)
    }
    False -> not_found_response()
  }
}

/// Handle OPTIONS preflight requests
fn route_options_preflight(path: String) -> Response {
  case string.starts_with(path, "/api/") {
    True -> cors_preflight_response()
    False -> not_found_response()
  }
}

/// Error handling wrapper - catches exceptions and returns generic error
fn catch_errors(handler: fn() -> Response) -> Result(Response, String) {
  // In Gleam, we use Result types rather than exceptions
  // This wrapper provides a uniform way to handle errors
  Ok(handler())
}

// ============================================
// CORS Middleware
// ============================================

/// CORS headers per boundary contract:
/// - Access-Control-Allow-Origin: *
/// - Access-Control-Allow-Methods: GET, POST, PATCH, DELETE
/// - Access-Control-Allow-Headers: Content-Type
fn add_cors_headers(response: Response) -> Response {
  let new_headers =
    response.headers
    |> dict.insert("Access-Control-Allow-Origin", "*")
    |> dict.insert("Access-Control-Allow-Methods", "GET, POST, PATCH, DELETE")
    |> dict.insert("Access-Control-Allow-Headers", "Content-Type")

  server.Response(..response, headers: new_headers)
}

/// Handle CORS preflight OPTIONS requests
fn cors_preflight_response() -> Response {
  server.json_response(204, "")
}

// ============================================
// Error Response Builders
// ============================================

/// Build 404 Not Found response per boundary contract
fn not_found_response() -> Response {
  let body =
    json.object([#("error", json.string("Not found"))])
    |> json.to_string()

  server.json_response(404, body)
}

/// Build 422 Validation Error response per boundary contract
/// Format: {errors: [{field: string, message: string}]}
fn validation_error_response(errors: List(FieldError)) -> Response {
  let error_items =
    list.map(errors, fn(e) {
      json.object([
        #("field", json.string(e.field)),
        #("message", json.string(e.message)),
      ])
    })

  let body =
    json.object([#("errors", json.array(error_items, fn(x) { x }))])
    |> json.to_string()

  server.json_response(422, body)
}

/// Build 400 Bad Request response
fn bad_request_response(message: String) -> Response {
  let body =
    json.object([#("error", json.string(message))])
    |> json.to_string()

  server.json_response(400, body)
}

/// Build 500 Server Error response - generic message per boundary contract
/// No stack traces or internal details leaked
fn server_error_response(_error_details: String) -> Response {
  let body =
    json.object([#("error", json.string("Internal server error"))])
    |> json.to_string()

  server.json_response(500, body)
}

/// Parse validation error strings into structured FieldErrors
fn parse_validation_errors(error_strings: List(String)) -> List(FieldError) {
  list.map(error_strings, fn(err) {
    // Parse error messages like "title is required" or "completed must be true or false"
    let parts = string.split(err, " ")
    let field = case parts {
      [first, ..] -> first
      [] -> "unknown"
    }
    FieldError(field: field, message: err)
  })
}

// ============================================
// Request Body Parsing
// ============================================

/// Parse JSON body for create todo request
fn parse_create_body(body: String) -> Result(List(#(String, String)), String) {
  // Parse JSON and extract fields
  let object_decoder = {
    use title <- decode.optional_field(
      "title",
      None,
      decode.optional(decode.string),
    )
    use description <- decode.optional_field(
      "description",
      None,
      decode.optional(decode.string),
    )
    use priority <- decode.optional_field(
      "priority",
      None,
      decode.optional(decode.string),
    )
    decode.success([title, description, priority])
  }

  case json.parse(from: body, using: object_decoder) {
    Ok(fields) -> {
      let payload = []

      // Extract title
      let payload = case fields {
        [Some(title), ..] -> [#("title", title), ..payload]
        _ -> payload
      }

      // Extract description
      let payload = case fields {
        [_, Some(desc), ..] -> [#("description", desc), ..payload]
        _ -> payload
      }

      // Extract priority
      let payload = case fields {
        [_, _, Some(priority)] -> [#("priority", priority), ..payload]
        _ -> payload
      }

      Ok(list.reverse(payload))
    }
    Error(_) -> Error("Invalid JSON")
  }
}

/// Parse JSON body for update todo request
fn parse_update_body(body: String) -> Result(List(#(String, String)), String) {
  let object_decoder = {
    use title <- decode.optional_field(
      "title",
      None,
      decode.optional(decode.string),
    )
    use description <- decode.optional_field(
      "description",
      None,
      decode.optional(decode.string),
    )
    use priority <- decode.optional_field(
      "priority",
      None,
      decode.optional(decode.string),
    )
    use completed <- decode.optional_field(
      "completed",
      None,
      decode.optional(decode.string),
    )
    decode.success(#(title, description, priority, completed))
  }

  case json.parse(from: body, using: object_decoder) {
    Ok(fields) -> {
      let changes = []

      // Extract title if present
      let changes = case fields.0 {
        Some(t) -> [#("title", t), ..changes]
        None -> changes
      }

      // Extract description if present
      let changes = case fields.1 {
        Some(d) -> [#("description", d), ..changes]
        None -> changes
      }

      // Extract priority if present
      let changes = case fields.2 {
        Some(p) -> [#("priority", p), ..changes]
        None -> changes
      }

      // Extract completed if present
      let changes = case fields.3 {
        Some(c) -> [#("completed", c), ..changes]
        None -> changes
      }

      Ok(list.reverse(changes))
    }
    Error(_) -> Error("Invalid JSON")
  }
}

// ============================================
// Handlers
// ============================================

fn health_handler() -> Response {
  server.json_response(
    200,
    json.object([#("status", json.string("ok"))]) |> json.to_string(),
  )
}

/// GET /api/todos - List all todos
fn list_todos_handler(store: Store, request: Request) -> Response {
  // Extract filter from query params if present
  let filter = parse_filter_from_path(request.path)

  case todo_store.list_all(store, filter) {
    Ok(todos) -> {
      let todo_jsons = list.map(todos, todo_to_json)
      let body = json.array(todo_jsons, fn(x) { x }) |> json.to_string()
      server.json_response(200, body)
    }
    Error(_) -> server_error_response("List failed")
  }
}

fn parse_filter_from_path(path: String) -> String {
  case string.split(path, "?") {
    [_, query] -> {
      case string.split(query, "=") {
        ["filter", value] -> value
        _ -> "all"
      }
    }
    _ -> "all"
  }
}

/// POST /api/todos - Create new todo
fn create_todo_handler(store: Store, request: Request) -> Response {
  // Check Content-Type header
  let has_json_content = case dict.get(request.headers, "content-type") {
    Ok(ct) -> string.contains(ct, "application/json")
    Error(_) -> False
  }

  case has_json_content {
    False -> bad_request_response("Content-Type must be application/json")
    True -> {
      case parse_create_body(request.body) {
        Ok(payload) -> {
          case todo_store.create_api(store, payload) {
            CreateOkResult(item) -> {
              let body = todo_to_json(item) |> json.to_string()
              server.json_response(201, body)
            }
            CreateErrorResult(ValidationErrorCreate(errors)) -> {
              let field_errors = parse_validation_errors(errors)
              validation_error_response(field_errors)
            }
          }
        }
        Error(_) -> bad_request_response("Invalid JSON body")
      }
    }
  }
}

/// GET /api/todos/:id - Get single todo
fn get_todo_handler(store: Store, id: String) -> Response {
  case todo_store.get_api(store, id) {
    GetOkResult(item) -> {
      let body = todo_to_json(item) |> json.to_string()
      server.json_response(200, body)
    }
    GetErrorResult(NotFoundGet) -> not_found_response()
  }
}

/// PATCH /api/todos/:id - Update todo
fn update_todo_handler(store: Store, id: String, request: Request) -> Response {
  // Check Content-Type header
  let has_json_content = case dict.get(request.headers, "content-type") {
    Ok(ct) -> string.contains(ct, "application/json")
    Error(_) -> False
  }

  case has_json_content {
    False -> bad_request_response("Content-Type must be application/json")
    True -> {
      case parse_update_body(request.body) {
        Ok(changes) -> {
          case todo_store.update_api(store, id, changes) {
            UpdateOkResult(item) -> {
              let body = todo_to_json(item) |> json.to_string()
              server.json_response(200, body)
            }
            UpdateErrorResult(NotFoundUpdate) -> not_found_response()
            UpdateErrorResult(ValidationErrorUpdate(errors)) -> {
              let field_errors = parse_validation_errors(errors)
              validation_error_response(field_errors)
            }
          }
        }
        Error(_) -> bad_request_response("Invalid JSON body")
      }
    }
  }
}

/// DELETE /api/todos/:id - Delete todo
fn delete_todo_handler(store: Store, id: String) -> Response {
  case todo_store.delete_api(store, id) {
    DeleteOkResult -> server.json_response(204, "")
    DeleteErrorResult(NotFoundDelete) -> not_found_response()
  }
}

// ============================================
// JSON Serialization
// ============================================

fn todo_to_json(item: Todo) -> json.Json {
  let description_json = case item.description {
    Some(d) -> json.string(d)
    None -> json.null()
  }

  json.object([
    #("id", json.string(item.id)),
    #("title", json.string(item.title)),
    #("description", description_json),
    #("priority", json.string(item.priority)),
    #("completed", json.bool(item.completed)),
    #("created_at", json.int(item.created_at)),
    #("updated_at", json.int(item.updated_at)),
  ])
}
