/// HTTP client effects for API communication with error handling

import frontend/model.{type ApiError, type FieldError, type Todo, FieldError, NetworkError, NotFoundError, ServerError, ValidationError}
import frontend/msg.{type Msg}
import gleam/dynamic/decode.{type Decoder}
import gleam/http
import gleam/http/request
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import lustre/effect.{type Effect}

/// API base URL
const api_base = "/api"

/// Decode a single todo from JSON
fn todo_decoder() -> Decoder(Todo) {
  use id <- decode.field("id", decode.string)
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", decode.string)
  use priority <- decode.field("priority", decode.string)
  use completed <- decode.field("completed", decode.bool)
  decode.success(model.Todo(id:, title:, description:, priority:, completed:))
}

/// Decode a list of todos from JSON (wrapped in "todos" field)
fn todos_response_decoder() -> Decoder(List(Todo)) {
  use todos <- decode.field("todos", decode.list(todo_decoder()))
  decode.success(todos)
}

/// Decode field errors from 422 validation error response
fn field_error_decoder() -> Decoder(FieldError) {
  use field <- decode.field("field", decode.string)
  use message <- decode.field("message", decode.string)
  decode.success(FieldError(field:, message:))
}

/// Decode validation errors from 422 response
fn validation_error_decoder() -> Decoder(List(FieldError)) {
  use errors <- decode.field("errors", decode.list(field_error_decoder()))
  decode.success(errors)
}

/// Extract API error from HTTP response
fn parse_api_error(status: Int, body: String) -> ApiError {
  case status {
    422 -> {
      case json.parse(body, validation_error_decoder()) {
        Ok(errors) -> ValidationError(errors)
        Error(_) -> ValidationError([FieldError("general", "Validation failed")])
      }
    }
    404 -> {
      case json.parse(body, decode.field("error", decode.string, decode.success)) {
        Ok(msg) -> NotFoundError(msg)
        Error(_) -> NotFoundError("Todo not found")
      }
    }
    _ -> {
      case json.parse(body, decode.field("error", decode.string, decode.success)) {
        Ok(msg) -> ServerError(msg)
        Error(_) -> ServerError("Request failed")
      }
    }
  }
}

/// Effect to load todos from API
pub fn load_todos() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let url = api_base <> "/todos"
    let req = request.new()
      |> request.set_method(http.Get)
      |> request.set_header("Accept", "application/json")
      |> request.set_path(url)

    case do_fetch(req) {
      Ok(#(status, body)) -> {
        case status {
          200 -> {
            case json.parse(body, todos_response_decoder()) {
              Ok(todos) -> dispatch(msg.LoadTodosSuccess(todos))
              Error(_) -> dispatch(msg.LoadTodosError(ServerError("Failed to parse response")))
            }
          }
          _ -> dispatch(msg.LoadTodosError(parse_api_error(status, body)))
        }
      }
      Error(_) -> dispatch(msg.LoadTodosError(NetworkError("Connection failed. Please try again.")))
    }
  })
}

/// Effect to submit a new todo
pub fn submit_todo(title: String, description: String, priority: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let url = api_base <> "/todos"
    let body_obj = json.object([
      #("title", json.string(title)),
      #("description", json.string(description)),
      #("priority", json.string(priority)),
    ])
    let body = json.to_string(body_obj)

    let req = request.new()
      |> request.set_method(http.Post)
      |> request.set_header("Content-Type", "application/json")
      |> request.set_header("Accept", "application/json")
      |> request.set_body(body)
      |> request.set_path(url)

    case do_fetch_with_body(req) {
      Ok(#(status, response_body)) -> {
        case status {
          201 -> {
            case json.parse(response_body, todo_decoder()) {
              Ok(todo_item) -> dispatch(msg.SubmitTodoSuccess(todo_item))
              Error(_) -> dispatch(msg.SubmitTodoError(ServerError("Failed to parse response")))
            }
          }
          422 -> dispatch(msg.SubmitTodoError(parse_api_error(status, response_body)))
          404 -> dispatch(msg.SubmitTodoError(parse_api_error(status, response_body)))
          _ -> dispatch(msg.SubmitTodoError(parse_api_error(status, response_body)))
        }
      }
      Error(_) -> dispatch(msg.SubmitTodoError(NetworkError("Connection failed. Please try again.")))
    }
  })
}

/// Effect to delete a todo
pub fn delete_todo(id: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let url = api_base <> "/todos/" <> id
    let req = request.new()
      |> request.set_method(http.Delete)
      |> request.set_header("Accept", "application/json")
      |> request.set_path(url)

    case do_fetch(req) {
      Ok(#(status, body)) -> {
        case status {
          200 | 204 -> dispatch(msg.DeleteTodoSuccess(id))
          404 -> dispatch(msg.DeleteTodoError(parse_api_error(status, body)))
          _ -> dispatch(msg.DeleteTodoError(parse_api_error(status, body)))
        }
      }
      Error(_) -> dispatch(msg.DeleteTodoError(NetworkError("Connection failed. Please try again.")))
    }
  })
}

/// Simplified fetch that returns status and body
fn do_fetch(req: request.Request(String)) -> Result(#(Int, String), Nil) {
  // In a real implementation, this would use the browser's fetch API
  // For now, we return an error to trigger the network error state
  Error(Nil)
}

/// Fetch with request body support
fn do_fetch_with_body(req: request.Request(String)) -> Result(#(Int, String), Nil) {
  // In a real implementation, this would use the browser's fetch API
  Error(Nil)
}
