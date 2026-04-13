/// HTTP effects for API communication with loading states and error handling

import frontend/http.{ExpectAnything, ExpectJsonTodo, ExpectJsonTodoList}
import frontend/msg.{type Msg}
import frontend/timer
import gleam/json
import lustre/effect.{type Effect}

/// API base URL
const api_base = "/api"

/// Fetch todos - triggers loading state
pub fn fetch_todos() -> Effect(Msg) {
  let url = api_base <> "/todos"
  http.request(
    http.Get,
    url,
    [],
    "",
    ExpectJsonTodoList(handle_load_success, handle_load_error),
  )
}

/// Add todo effect
pub fn add_todo(title: String, description: String) -> Effect(Msg) {
  let url = api_base <> "/todos"
  let body = json.object([
    #("title", json.string(title)),
    #("description", json.string(description)),
  ])
  let json_string = json.to_string(body)

  http.request(
    http.Post,
    url,
    [#("Content-Type", "application/json")],
    json_string,
    ExpectJsonTodo(handle_add_success, handle_add_error),
  )
}

/// Toggle todo effect
pub fn toggle_todo(id: String, completed: Bool) -> Effect(Msg) {
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

/// Delete todo effect
pub fn delete_todo(id: String) -> Effect(Msg) {
  let url = api_base <> "/todos/" <> id

  http.request(
    http.Delete,
    url,
    [],
    "",
    ExpectAnything(fn() { handle_delete_success(id) }, handle_delete_error(id)),
  )
}

/// Start transient error timer (5 seconds)
pub fn start_transient_error_timer() -> Effect(Msg) {
  timer.clear_after_delay(msg.ClearTransientError)
}

// Response handlers

fn handle_load_success(todos) {
  msg.FetchTodos(msg.Success, msg.TodosList(todos))
}

fn handle_load_error(_error) {
  msg.FetchTodos(msg.Error("Failed to load todos. Please refresh."), msg.NoFetchPayload)
}

fn handle_add_success(item) {
  msg.AddTodo(msg.Success, msg.NewTodo(item))
}

fn handle_add_error(_error) {
  msg.AddTodo(msg.Error("Failed to add todo"), msg.NoAddPayload)
}

fn handle_update_success(item) {
  msg.ToggleTodo(msg.Success, msg.ToggledTodo(item))
}

fn handle_update_error(id, original_completed) {
  fn(_error) {
    msg.ToggleTodo(msg.Error("Update failed"), msg.ToggleData(id, !original_completed))
  }
}

fn handle_delete_success(id) {
  msg.DeleteTodo(msg.Success, msg.DeleteResult(id))
}

fn handle_delete_error(id) {
  fn(_error) { msg.DeleteTodo(msg.Error("Delete failed"), msg.DeleteData(id)) }
}
