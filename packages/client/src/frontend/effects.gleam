/// HTTP effects for API communication with error handling

import frontend/msg.{type Msg}
import frontend/model as model
import frontend/http.{ExpectJsonTodo, ExpectJsonTodoList, ExpectAnything}
import frontend/timer
import gleam/json
import lustre/effect.{type Effect}

/// API base URL
const api_base = "/api"

/// Load todos from the API
pub fn load_todos() -> Effect(Msg) {
  let url = api_base <> "/todos"
  http.request(
    http.Get,
    url,
    [],
    "",
    ExpectJsonTodoList(handle_load_success, handle_load_error),
  )
}

/// Create a new todo
pub fn create_todo(title: String) -> Effect(Msg) {
  let url = api_base <> "/todos"
  let body = json.object([#("title", json.string(title))])
  let json_string = json.to_string(body)

  http.request(
    http.Post,
    url,
    [#("Content-Type", "application/json")],
    json_string,
    ExpectJsonTodo(handle_add_success, handle_add_error),
  )
}

/// Update a todo's completion status
pub fn update_todo(id: String, completed: Bool) -> Effect(Msg) {
  let url = api_base <> "/todos/" <> id
  let body = json.object([#("completed", json.bool(completed))])
  let json_string = json.to_string(body)

  http.request(
    http.Patch,
    url,
    [#("Content-Type", "application/json")],
    json_string,
    ExpectJsonTodo(handle_update_success, handle_update_error(id, completed)),
  )
}

/// Delete a todo
pub fn delete_todo(id: String, item: model.Todo) -> Effect(Msg) {
  let url = api_base <> "/todos/" <> id

  http.request(
    http.Delete,
    url,
    [],
    "",
    ExpectAnything(handle_delete_success(id), handle_delete_error(id, item)),
  )
}

/// Start transient error timer (5 seconds)
pub fn start_transient_error_timer() -> Effect(Msg) {
  timer.clear_after_delay(msg.ClearTransientError)
}

// Response handlers

fn handle_load_success(todos: List(model.Todo)) -> Msg {
  msg.LoadTodosSuccess(todos)
}

fn handle_load_error(_error: String) -> Msg {
  msg.LoadTodosError("Failed to load todos. Please refresh.")
}

fn handle_add_success(new_item: model.Todo) -> Msg {
  msg.AddTodoSuccess(new_item)
}

fn handle_add_error(_error: String) -> Msg {
  msg.AddTodoError("Failed to create todo. Please try again.")
}

fn handle_update_success(updated: model.Todo) -> Msg {
  msg.UpdateTodoSuccess(updated)
}

fn handle_update_error(id: String, attempted_completed: Bool) -> fn(String) -> Msg {
  fn(_error) {
    let original = !attempted_completed
    msg.UpdateTodoError(id, original, "Update failed")
  }
}

fn handle_delete_success(id: String) -> fn() -> Msg {
  fn() { msg.DeleteTodoSuccess(id) }
}

fn handle_delete_error(id: String, item: model.Todo) -> fn(String) -> Msg {
  fn(_error) { msg.DeleteTodoError(id, item, "Delete failed") }
}
