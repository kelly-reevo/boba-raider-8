/// API effects for todo management

import frontend/msg.{type Msg}
import gleam/dynamic.{type Dynamic}
import gleam/json
import gleam/option.{type Option}
import gleam/result
import lustre/effect.{type Effect}
import shared.{type Priority}

/// Fetch all todos from the API
pub fn fetch_todos() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    do_fetch_todos(dispatch)
  })
}

/// Create a new todo via API
pub fn create_todo(title: String, description: Option(String)) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    do_create_todo(title, description, dispatch)
  })
}

/// Update a todo via API
pub fn update_todo(
  id: String,
  title: String,
  description: Option(String),
  priority: Priority,
  completed: Bool,
) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    do_update_todo(id, title, description, priority, completed, dispatch)
  })
}

/// Delete a todo via API
pub fn delete_todo(id: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    do_delete_todo(id, dispatch)
  })
}

// FFI functions for JavaScript fetch API
@external(javascript, "../frontend_ffi.mjs", "fetchTodos")
fn do_fetch_todos(dispatch: fn(Msg) -> Nil) -> Nil

@external(javascript, "../frontend_ffi.mjs", "createTodo")
fn do_create_todo(
  title: String,
  description: Option(String),
  dispatch: fn(Msg) -> Nil,
) -> Nil

@external(javascript, "../frontend_ffi.mjs", "updateTodo")
fn do_update_todo(
  id: String,
  title: String,
  description: Option(String),
  priority: Priority,
  completed: Bool,
  dispatch: fn(Msg) -> Nil,
) -> Nil

@external(javascript, "../frontend_ffi.mjs", "deleteTodo")
fn do_delete_todo(id: String, dispatch: fn(Msg) -> Nil) -> Nil
