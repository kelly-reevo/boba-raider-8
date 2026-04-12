/// API effects for the frontend

import frontend/msg.{type Msg}
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/json
import gleam/option.{type Option}
import gleam/string
import lustre/effect.{type Effect}
import shared.{type Priority, type Todo, priority_from_string}

/// API base URL
const api_base = "/api"

/// Fetch todos from the API on page load (alias for load_todos)
pub fn fetch_todos() -> Effect(Msg) {
  load_todos()
}

/// Load all todos from the API
pub fn load_todos() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let url = api_base <> "/todos"
    let req = request.new()
      |> request.set_method(http.Get)
      |> request.set_host("")
      |> request.set_path(url)

    do_fetch(req, fn(response) {
      case response {
        Ok(json_str) -> {
          case parse_todos(json_str) {
            Ok(todos) -> dispatch(msg.LoadTodosOk(todos))
            Error(err) -> dispatch(msg.LoadTodosError(err))
          }
        }
        Error(err) -> dispatch(msg.LoadTodosError(err))
      }
    })
  })
}

/// Delete a todo by ID
pub fn delete_todo(id: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let url = api_base <> "/todos/" <> id
    let req = request.new()
      |> request.set_method(http.Delete)
      |> request.set_host("")
      |> request.set_path(url)

    do_fetch(req, fn(response) {
      case response {
        Ok(_) -> dispatch(msg.DeleteTodoOk(id))
        Error(err) -> dispatch(msg.DeleteTodoError(err))
      }
    })
  })
}

/// External FFI for fetch - implemented in JavaScript
@external(javascript, "../client_ffi.mjs", "fetch_json")
fn do_fetch(req: request.Request(String), callback: fn(Result(String, String)) -> Nil) -> Nil

/// FFI to JavaScript fetch for getting todos (legacy support)
@external(javascript, "../client_ffi.js", "fetchTodos")
fn do_fetch_todos(req: request.Request(String), dispatch: fn(Msg) -> Nil) -> Nil

/// JSON decoder for Priority
fn priority_decoder() -> decode.Decoder(Priority) {
  decode.string
  |> decode.then(fn(str) {
    case priority_from_string(str) {
      Ok(p) -> decode.success(p)
      Error(_) -> decode.success(shared.Medium)
    }
  })
}

/// JSON decoder for optional string (null -> None)
fn optional_string_decoder() -> decode.Decoder(Option(String)) {
  decode.optional(decode.string)
}

/// JSON decoder for a single Todo
fn todo_decoder() -> decode.Decoder(Todo) {
  use id <- decode.field("id", decode.string)
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", optional_string_decoder())
  use priority <- decode.field("priority", priority_decoder())
  use completed <- decode.field("completed", decode.bool)
  use created_at <- decode.field("created_at", decode.string)
  use updated_at <- decode.field("updated_at", decode.string)

  decode.success(shared.Todo(
    id: id,
    title: title,
    description: description,
    priority: priority,
    completed: completed,
    created_at: created_at,
    updated_at: updated_at,
  ))
}

/// JSON decoder for list of todos
pub fn todos_decoder() -> decode.Decoder(List(Todo)) {
  decode.list(todo_decoder())
}

/// Parse JSON string to list of todos
pub fn parse_todos(json_str: String) -> Result(List(Todo), String) {
  case json.parse(json_str, todos_decoder()) {
    Ok(todos) -> Ok(todos)
    Error(e) -> Error("Failed to parse todos: " <> string.inspect(e))
  }
}
