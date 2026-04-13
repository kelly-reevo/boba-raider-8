import frontend/model.{type Todo, Todo}
import frontend/msg.{type Msg}
import gleam/dynamic
import gleam/http
import gleam/http/request
import gleam/json
import gleam/list
import gleam/result
import lustre/effect.{type Effect}

/// API base URL
const api_base = "/api"

/// Fetch all todos from the API
pub fn fetch_todos() -> Effect(Msg) {
  let url = api_base <> "/todos"

  effect.from(fn(dispatch) {
    let req = request.new()
      |> request.set_method(http.Get)
      |> request.set_header("Accept", "application/json")
      |> request.set_path(url)

    // Use JavaScript fetch via FFI
    do_fetch_todos(req, dispatch)
  })
}

/// Submit a new todo to the API
pub fn submit_todo(title: String, description: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let body = json.object([
      #("title", json.string(title)),
      #("description", json.string(description)),
      #("completed", json.bool(False))
    ])
    |> json.to_string

    let req = request.new()
      |> request.set_method(http.Post)
      |> request.set_header("Content-Type", "application/json")
      |> request.set_header("Accept", "application/json")
      |> request.set_path(api_base <> "/todos")
      |> request.set_body(body)

    do_submit_todo(req, dispatch)
  })
}

/// Toggle a todo's completed status
pub fn toggle_todo(todo_id: String, completed: Bool) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let body = json.object([
      #("completed", json.bool(completed))
    ])
    |> json.to_string

    let req = request.new()
      |> request.set_method(http.Patch)
      |> request.set_header("Content-Type", "application/json")
      |> request.set_header("Accept", "application/json")
      |> request.set_path(api_base <> "/todos/" <> todo_id)
      |> request.set_body(body)

    do_toggle_todo(req, todo_id, dispatch)
  })
}

/// Delete a todo
pub fn delete_todo(todo_id: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let req = request.new()
      |> request.set_method(http.Delete)
      |> request.set_header("Accept", "application/json")
      |> request.set_path(api_base <> "/todos/" <> todo_id)

    do_delete_todo(req, todo_id, dispatch)
  })
}

// FFI functions for JavaScript fetch
@external(javascript, "../ffi/fetch.js", "fetchTodos")
fn do_fetch_todos(req: request.Request(String), dispatch: fn(Msg) -> Nil) -> Nil

@external(javascript, "../ffi/fetch.js", "submitTodo")
fn do_submit_todo(req: request.Request(String), dispatch: fn(Msg) -> Nil) -> Nil

@external(javascript, "../ffi/fetch.js", "toggleTodo")
fn do_toggle_todo(req: request.Request(String), todo_id: String, dispatch: fn(Msg) -> Nil) -> Nil

@external(javascript, "../ffi/fetch.js", "deleteTodo")
fn do_delete_todo(req: request.Request(String), todo_id: String, dispatch: fn(Msg) -> Nil) -> Nil
