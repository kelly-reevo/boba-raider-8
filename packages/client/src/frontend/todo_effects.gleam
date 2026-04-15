/// Effects for todo operations with extensible HTTP client

import frontend/origin_ffi
import frontend/todo_model.{type Todo, Todo}
import frontend/todo_msg.{type TodoHttpError, type TodoMsg, type ToggleResult, ToggleResult, TodoDecodeError, TodoNetworkError, TodoServerError}
import gleam/dynamic/decode
import gleam/fetch
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/javascript/promise
import gleam/json
import lustre/effect.{type Effect}

/// API base path for todo operations
const api_base = "/api/todos"

/// Decoder for single todo item
fn todo_decoder() -> decode.Decoder(Todo) {
  use id <- decode.field("id", decode.string)
  use title <- decode.field("title", decode.string)
  use completed <- decode.field("completed", decode.bool)
  decode.success(Todo(id:, title:, completed:))
}

/// Decoder for list of todos
fn todos_decoder() -> decode.Decoder(List(Todo)) {
  decode.list(todo_decoder())
}

/// Decoder for toggle response
fn toggle_response_decoder() -> decode.Decoder(ToggleResult) {
  use id <- decode.field("id", decode.string)
  use completed <- decode.field("completed", decode.bool)
  use todos <- decode.field("todos", todos_decoder())
  use active_count <- decode.field("active_count", decode.int)
  decode.success(ToggleResult(id:, completed:, todos:, active_count:))
}

/// Make GET request to API
fn api_get(
  path: String,
  decoder: decode.Decoder(a),
  to_msg: fn(Result(a, TodoHttpError)) -> TodoMsg,
) -> Effect(TodoMsg) {
  effect.from(fn(dispatch) {
    let full_path = origin_ffi.get_origin() <> path
    let req_result = request.to(full_path)

    case req_result {
      Error(_) -> dispatch(to_msg(Error(TodoNetworkError)))
      Ok(req) -> {
        fetch.send(req)
        |> promise.try_await(fetch.read_text_body)
        |> promise.map(fn(result) {
          case result {
            Ok(resp) -> decode_response(resp, decoder, to_msg)
            Error(_) -> to_msg(Error(TodoNetworkError))
          }
        })
        |> promise.tap(dispatch)
        Nil
      }
    }
  })
}

/// Make POST request to API
fn api_post(
  path: String,
  decoder: decode.Decoder(a),
  to_msg: fn(Result(a, TodoHttpError)) -> TodoMsg,
) -> Effect(TodoMsg) {
  effect.from(fn(dispatch) {
    let full_path = origin_ffi.get_origin() <> path
    let req_result = request.to(full_path)

    case req_result {
      Error(_) -> dispatch(to_msg(Error(TodoNetworkError)))
      Ok(req) -> {
        let req =
          req
          |> request.set_method(http.Post)
          |> request.set_header("content-type", "application/json")
          |> request.set_body(json.to_string(json.null()))

        fetch.send(req)
        |> promise.try_await(fetch.read_text_body)
        |> promise.map(fn(result) {
          case result {
            Ok(resp) -> decode_response(resp, decoder, to_msg)
            Error(_) -> to_msg(Error(TodoNetworkError))
          }
        })
        |> promise.tap(dispatch)
        Nil
      }
    }
  })
}

/// Decode HTTP response based on status code
fn decode_response(
  resp: response.Response(String),
  decoder: decode.Decoder(a),
  to_msg: fn(Result(a, TodoHttpError)) -> TodoMsg,
) -> TodoMsg {
  case resp.status {
    status if status >= 200 && status <= 299 -> {
      case json.parse(resp.body, decoder) {
        Ok(data) -> to_msg(Ok(data))
        Error(_) -> to_msg(Error(TodoDecodeError))
      }
    }
    status -> to_msg(Error(TodoServerError(status)))
  }
}

/// Fetch all todos from server
pub fn fetch_todos() -> Effect(TodoMsg) {
  api_get(api_base, todos_decoder(), todo_msg.GotTodos)
}

/// Toggle todo completion status
/// Calls POST /api/todos/:id/toggle
pub fn post_toggle(id: String) -> Effect(TodoMsg) {
  let path = api_base <> "/" <> id <> "/toggle"
  api_post(path, toggle_response_decoder(), todo_msg.TodoToggled)
}

/// Delete todo
/// Calls DELETE /api/todos/:id
pub fn delete_todo(id: String) -> Effect(TodoMsg) {
  effect.from(fn(dispatch) {
    let full_path = origin_ffi.get_origin() <> api_base <> "/" <> id
    let req_result = request.to(full_path)

    case req_result {
      Error(_) -> dispatch(todo_msg.TodoDeleted(Error(TodoNetworkError)))
      Ok(req) -> {
        let req =
          req
          |> request.set_method(http.Delete)
          |> request.set_header("content-type", "application/json")

        fetch.send(req)
        |> promise.try_await(fetch.read_text_body)
        |> promise.map(fn(result) {
          case result {
            Ok(resp) -> {
              case resp.status {
                status if status >= 200 && status <= 299 -> {
                  todo_msg.TodoDeleted(Ok(id))
                }
                status -> todo_msg.TodoDeleted(Error(TodoServerError(status)))
              }
            }
            Error(_) -> todo_msg.TodoDeleted(Error(TodoNetworkError))
          }
        })
        |> promise.tap(dispatch)
        Nil
      }
    }
  })
}
