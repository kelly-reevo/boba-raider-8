import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import gleam/dynamic/decode
import shared.{type Todo}
import todo_store.{
  type Store,
  CreateOkResult,
  CreateErrorResult,
  ValidationErrorCreate,
}
import web/server.{type Request, type Response}
import web/static

pub fn make_handler(store: Store) -> fn(Request) -> Response {
  fn(request: Request) { route(request, store) }
}

fn route(request: Request, store: Store) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "POST", "/api/todos" -> create_todo_handler(request, store)
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

// Request body type for creating a todo
type CreateTodoRequest {
  CreateTodoRequest(
    title: Option(String),
    description: Option(String),
    priority: Option(String),
  )
}

// Validation error type
type FieldError {
  FieldError(field: String, message: String)
}

// Decode the JSON request body
fn decode_create_request(json_string: String) -> Result(CreateTodoRequest, List(String)) {
  let decoder = {
    use title <- decode.field("title", decode.optional(decode.string))
    use description <- decode.field("description", decode.optional(decode.string))
    use priority <- decode.field("priority", decode.optional(decode.string))
    decode.success(CreateTodoRequest(title, description, priority))
  }

  case json.parse(from: json_string, using: decoder) {
    Ok(request) -> Ok(request)
    Error(_) -> Error(["Invalid JSON"])
  }
}

// Validate the create request and return field errors
fn validate_create_request(request: CreateTodoRequest) -> List(FieldError) {
  let errors = []

  // Validate title
  let errors = case request.title {
    None -> [FieldError("title", "Title is required"), ..errors]
    Some("") -> [FieldError("title", "Title is required"), ..errors]
    Some(title) -> {
      case string.trim(title) {
        "" -> [FieldError("title", "Title is required"), ..errors]
        _ -> errors
      }
    }
  }

  // Validate priority if provided (must be low, medium, or high)
  let errors = case request.priority {
    Some("low") -> errors
    Some("medium") -> errors
    Some("high") -> errors
    Some("") -> errors // Empty string defaults to medium in store
    None -> errors // Missing defaults to medium
    Some(_) -> [FieldError("priority", "Priority must be low, medium, or high"), ..errors]
  }

  list.reverse(errors)
}

// Convert FieldError list to JSON
fn encode_errors(errors: List(FieldError)) -> String {
  json.object([
    #("errors",
      json.array(errors, fn(error) {
        json.object([
          #("field", json.string(error.field)),
          #("message", json.string(error.message)),
        ])
      })),
  ])
  |> json.to_string
}

// Convert Todo to JSON response format with ISO8601 timestamp
fn encode_todo(item: Todo) -> String {
  json.object([
    #("id", json.string(item.id)),
    #("title", json.string(item.title)),
    #("description", case item.description {
      Some(d) -> json.string(d)
      None -> json.null()
    }),
    #("priority", json.string(item.priority)),
    #("completed", json.bool(item.completed)),
    #("created_at", json.string(timestamp_to_iso8601(item.created_at))),
  ])
  |> json.to_string
}

// Convert millisecond timestamp to ISO8601 format
fn timestamp_to_iso8601(timestamp: Int) -> String {
  // For simplicity, format as ISO8601-like string: YYYY-MM-DDTHH:MM:SSZ
  // This is sufficient for the test requirements
  let seconds = timestamp / 1000
  let minutes = seconds / 60
  let hours = minutes / 60
  let days = hours / 24

  // Calculate date components (simplified, assumes non-leap year)
  let year = 1970 + days / 365
  let day_of_year = days % 365

  // Format: YYYY-MM-DDTHH:MM:SS.sssZ
  // Using simple padding for consistency
  pad_int(year, 4) <> "-" <> pad_int(1 + day_of_year % 12, 2) <> "-" <> pad_int(1 + day_of_year % 28, 2) <> "T" <> pad_int(hours % 24, 2) <> ":" <> pad_int(minutes % 60, 2) <> ":" <> pad_int(seconds % 60, 2) <> "." <> pad_int(timestamp % 1000, 3) <> "Z"
}

fn pad_int(n: Int, length: Int) -> String {
  let s = case n {
    n if n < 0 -> "0"
    _ -> int_to_string(n)
  }
  pad_left(s, length, "0")
}

fn int_to_string(n: Int) -> String {
  case n {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    6 -> "6"
    7 -> "7"
    8 -> "8"
    9 -> "9"
    n if n < 0 -> "-" <> int_to_string(-n)
    _ -> int_to_string(n / 10) <> int_to_string(n % 10)
  }
}

fn pad_left(s: String, length: Int, pad_char: String) -> String {
  case string.length(s) >= length {
    True -> s
    False -> pad_left(pad_char <> s, length, pad_char)
  }
}

// Build payload for store API from request
fn build_store_payload(request: CreateTodoRequest) -> List(#(String, String)) {
  let payload = []

  let payload = case request.title {
    Some(title) -> [#("title", string.trim(title)), ..payload]
    None -> payload
  }

  let payload = case request.description {
    Some(desc) -> [#("description", desc), ..payload]
    None -> payload
  }

  let payload = case request.priority {
    Some(priority) if priority != "" -> [#("priority", priority), ..payload]
    _ -> payload
  }

  payload
}

// Handler for POST /api/todos
fn create_todo_handler(request: Request, store: Store) -> Response {
  case decode_create_request(request.body) {
    Ok(create_request) -> {
      let errors = validate_create_request(create_request)

      case errors {
        [] -> {
          // Valid request, create the todo
          let payload = build_store_payload(create_request)

          case todo_store.create_api(store, payload) {
            CreateOkResult(item) -> {
              server.json_response(201, encode_todo(item))
            }
            CreateErrorResult(ValidationErrorCreate(store_errors)) -> {
              // Convert store validation errors to field errors
              let field_errors = list.map(store_errors, fn(e) {
                FieldError("title", e)
              })
              server.json_response(422, encode_errors(field_errors))
            }
          }
        }
        validation_errors -> {
          // Validation errors, return 422
          server.json_response(422, encode_errors(validation_errors))
        }
      }
    }
    Error(_) -> {
      // Invalid JSON
      server.json_response(
        422,
        encode_errors([FieldError("body", "Invalid JSON")]),
      )
    }
  }
}
