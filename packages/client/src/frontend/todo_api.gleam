/// HTTP client functions for todo API operations
/// Uses gleam_fetch to call backend endpoints with JSON encoding/decoding

import frontend/filter.{type Filter}
import frontend/msg.{type HttpError, DecodeError, NetworkError, ServerError, ValidationError}
import gleam/dynamic/decode
import gleam/fetch
import gleam/http
import gleam/http/request
import gleam/javascript/promise
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import gleam/result
import shared.{type Priority, type Todo, High, Low, Medium, Todo}
import shared/todo_validation.{type TodoPatch}

@external(javascript, "./origin_ffi.mjs", "get_origin")
fn get_origin() -> String

/// API base path for todos
const todos_path = "/api/todos"

/// Error type for API operations
pub type TodoApiError {
  TodoNetworkError
  TodoDecodeError
  TodoServerError(Int)
  TodoValidationError(List(String))
}

/// Convert internal error to msg.HttpError
fn to_http_error(error: TodoApiError) -> HttpError {
  case error {
    TodoNetworkError -> NetworkError
    TodoDecodeError -> DecodeError
    TodoServerError(status) -> ServerError(status)
    TodoValidationError(errors) -> ValidationError(errors)
  }
}

/// Decode a Priority from a string
fn decode_priority(priority_str: String) -> Result(Priority, Nil) {
  case priority_str {
    "high" -> Ok(High)
    "medium" -> Ok(Medium)
    "low" -> Ok(Low)
    _ -> Error(Nil)
  }
}

/// Encode a Priority to a string
fn encode_priority(priority: Priority) -> String {
  case priority {
    High -> "high"
    Medium -> "medium"
    Low -> "low"
  }
}

/// Decoder for Todo type from JSON
fn todo_decoder() -> decode.Decoder(Todo) {
  use id <- decode.field("id", decode.string)
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  use priority_str <- decode.field("priority", decode.string)
  use completed <- decode.field("completed", decode.bool)

  case decode_priority(priority_str) {
    Ok(priority) -> decode.success(Todo(id:, title:, description:, priority:, completed:))
    Error(_) -> decode.failure(Todo(id: "", title: "", description: None, priority: Low, completed: False), "Invalid priority value")
  }
}

/// Decoder for a list of Todos
fn todo_list_decoder() -> decode.Decoder(List(Todo)) {
  decode.list(todo_decoder())
}

/// Decoder for errors array
fn errors_list_decoder() -> decode.Decoder(List(String)) {
  use errors <- decode.field("errors", decode.list(decode.string))
  decode.success(errors)
}

/// Decoder for single error string
fn single_error_decoder() -> decode.Decoder(String) {
  use error <- decode.field("error", decode.string)
  decode.success(error)
}

/// Extract error messages from a 400 validation error response
fn extract_validation_errors(body: String) -> List(String) {
  // Try to parse errors array from JSON
  case json.parse(body, errors_list_decoder()) {
    Ok(errors) -> errors
    Error(_) -> {
      case json.parse(body, single_error_decoder()) {
        Ok(error) -> [error]
        Error(_) -> ["Validation failed"]
      }
    }
  }
}

/// Make a GET request to the API
fn api_get(
  path: String,
  decoder: decode.Decoder(a),
) -> promise.Promise(Result(a, TodoApiError)) {
  let url = get_origin() <> path

  case request.to(url) {
    Ok(req) -> {
      fetch.send(req)
      |> promise.try_await(fetch.read_text_body)
      |> promise.map(fn(result) {
        case result {
          Ok(resp) -> {
            case resp.status {
              status if status >= 200 && status < 300 -> {
                case json.parse(resp.body, decoder) {
                  Ok(value) -> Ok(value)
                  Error(_) -> Error(TodoDecodeError)
                }
              }
              400 -> {
                let errors = extract_validation_errors(resp.body)
                Error(TodoValidationError(errors))
              }
              status -> Error(TodoServerError(status))
            }
          }
          Error(_) -> Error(TodoNetworkError)
        }
      })
    }
    Error(_) -> promise.resolve(Error(TodoNetworkError))
  }
}

/// Make a POST request to the API with a JSON body
fn api_post(
  path: String,
  body: Json,
  decoder: decode.Decoder(a),
) -> promise.Promise(Result(a, TodoApiError)) {
  let url = get_origin() <> path

  case request.to(url) {
    Ok(req) -> {
      let req =
        req
        |> request.set_method(http.Post)
        |> request.set_header("content-type", "application/json")
        |> request.set_body(json.to_string(body))

      fetch.send(req)
      |> promise.try_await(fetch.read_text_body)
      |> promise.map(fn(result) {
        case result {
          Ok(resp) -> {
            case resp.status {
              status if status >= 200 && status < 300 -> {
                case json.parse(resp.body, decoder) {
                  Ok(value) -> Ok(value)
                  Error(_) -> Error(TodoDecodeError)
                }
              }
              400 -> {
                let errors = extract_validation_errors(resp.body)
                Error(TodoValidationError(errors))
              }
              status -> Error(TodoServerError(status))
            }
          }
          Error(_) -> Error(TodoNetworkError)
        }
      })
    }
    Error(_) -> promise.resolve(Error(TodoNetworkError))
  }
}

/// Make a PATCH request to the API with a JSON body
fn api_patch(
  path: String,
  body: Json,
  decoder: decode.Decoder(a),
) -> promise.Promise(Result(a, TodoApiError)) {
  let url = get_origin() <> path

  case request.to(url) {
    Ok(req) -> {
      let req =
        req
        |> request.set_method(http.Patch)
        |> request.set_header("content-type", "application/json")
        |> request.set_body(json.to_string(body))

      fetch.send(req)
      |> promise.try_await(fetch.read_text_body)
      |> promise.map(fn(result) {
        case result {
          Ok(resp) -> {
            case resp.status {
              status if status >= 200 && status < 300 -> {
                case json.parse(resp.body, decoder) {
                  Ok(value) -> Ok(value)
                  Error(_) -> Error(TodoDecodeError)
                }
              }
              400 -> {
                let errors = extract_validation_errors(resp.body)
                Error(TodoValidationError(errors))
              }
              404 -> Error(TodoServerError(404))
              status -> Error(TodoServerError(status))
            }
          }
          Error(_) -> Error(TodoNetworkError)
        }
      })
    }
    Error(_) -> promise.resolve(Error(TodoNetworkError))
  }
}

/// Make a DELETE request to the API
fn api_delete(path: String) -> promise.Promise(Result(Bool, TodoApiError)) {
  let url = get_origin() <> path

  case request.to(url) {
    Ok(req) -> {
      let req =
        req
        |> request.set_method(http.Delete)

      fetch.send(req)
      |> promise.try_await(fetch.read_text_body)
      |> promise.map(fn(result) {
        case result {
          Ok(resp) -> {
            case resp.status {
              status if status >= 200 && status < 300 -> Ok(True)
              404 -> Error(TodoServerError(404))
              status -> Error(TodoServerError(status))
            }
          }
          Error(_) -> Error(TodoNetworkError)
        }
      })
    }
    Error(_) -> promise.resolve(Error(TodoNetworkError))
  }
}

/// Build query string for filter parameter
fn build_filter_query(filter: Filter) -> String {
  case filter {
    filter.All -> ""
    filter.Active -> "?filter=active"
    filter.Completed -> "?filter=completed"
  }
}

/// Fetch todos from the API with optional filter
pub fn fetch_todos(filter_state: Filter) -> promise.Promise(Result(List(Todo), HttpError)) {
  let query = build_filter_query(filter_state)
  let path = todos_path <> query

  api_get(path, todo_list_decoder())
  |> promise.map(fn(result) {
    result.map_error(result, with: to_http_error)
  })
}

/// Create a new todo
pub fn create_todo(
  title: String,
  description: Option(String),
  priority: Priority,
) -> promise.Promise(Result(Todo, HttpError)) {
  let description_json = case description {
    Some(d) -> json.string(d)
    None -> json.null()
  }

  let body =
    json.object([
      #("title", json.string(title)),
      #("description", description_json),
      #("priority", json.string(encode_priority(priority))),
    ])

  api_post(todos_path, body, todo_decoder())
  |> promise.map(fn(result) {
    result.map_error(result, with: to_http_error)
  })
}

/// Build a patch JSON object from TodoPatch, only including changed fields
fn build_patch_json(patch: TodoPatch) -> Json {
  let fields = []

  let fields = case patch.title {
    Some(title) -> [#("title", json.string(title)), ..fields]
    None -> fields
  }

  let fields = case patch.description {
    Some(desc) -> [#("description", json.string(desc)), ..fields]
    None -> {
      // Check if description should be explicitly set to null
      // In Gleam, we need to determine if description was explicitly cleared
      // For now, only include if Some
      fields
    }
  }

  let fields = case patch.priority {
    Some(p) -> [#("priority", json.string(encode_priority(p))), ..fields]
    None -> fields
  }

  let fields = case patch.completed {
    Some(c) -> [#("completed", json.bool(c)), ..fields]
    None -> fields
  }

  json.object(fields)
}

/// Update an existing todo with partial changes
pub fn update_todo(
  id: String,
  changes: TodoPatch,
) -> promise.Promise(Result(Todo, HttpError)) {
  let path = todos_path <> "/" <> id
  let body = build_patch_json(changes)

  api_patch(path, body, todo_decoder())
  |> promise.map(fn(result) {
    result.map_error(result, with: to_http_error)
  })
}

/// Delete a todo by ID
pub fn delete_todo(id: String) -> promise.Promise(Result(Bool, HttpError)) {
  let path = todos_path <> "/" <> id

  api_delete(path)
  |> promise.map(fn(result) {
    result.map_error(result, with: to_http_error)
  })
}
