/// API effects for fetching and manipulating todos

import frontend/msg.{type Msg}
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/json
import gleam/option.{type Option}
import gleam/string
import lustre/effect.{type Effect}
import shared.{type Priority, type Todo, priority_from_string}

/// Fetch todos from the API on page load
pub fn fetch_todos() -> Effect(Msg) {
  let req = request.new()
    |> request.set_host("localhost")
    |> request.set_port(3000)
    |> request.set_path("/api/todos")
    |> request.set_method(http.Get)

  effect.from(fn(dispatch) {
    do_fetch_todos(req, dispatch)
  })
}

/// FFI to JavaScript fetch for getting todos
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
