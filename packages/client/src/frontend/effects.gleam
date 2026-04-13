/// Fetch todos from GET /api/todos
import frontend/msg.{type Msg}
import lustre/effect.{type Effect}

/// Fetch all todos from API
pub fn fetch_todos() -> Effect(Msg) {
  use dispatch <- effect.from

  // For JavaScript target, use browser fetch via FFI
  do_fetch_todos(dispatch, "/api/todos")
  Nil
}

/// Delete a todo by ID
pub fn delete_todo(id: String) -> Effect(Msg) {
  use dispatch <- effect.from
  do_delete_todos(dispatch, id)
  Nil
}

/// Toggle todo completion via PATCH
pub fn patch_todo(id: String, completed: Bool) -> Effect(Msg) {
  use dispatch <- effect.from
  do_patch_todo(dispatch, id, completed)
  Nil
}

@external(javascript, "./effects_ffi.mjs", "fetchTodos")
fn do_fetch_todos(dispatch: fn(Msg) -> Nil, url: String) -> Nil

@external(javascript, "./effects_ffi.mjs", "deleteTodo")
fn do_delete_todos(dispatch: fn(Msg) -> Nil, id: String) -> Nil

@external(javascript, "./effects_ffi.mjs", "patchTodo")
fn do_patch_todo(dispatch: fn(Msg) -> Nil, id: String, completed: Bool) -> Nil
