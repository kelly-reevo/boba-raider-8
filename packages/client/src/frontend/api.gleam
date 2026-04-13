/// FFI wrapper for JavaScript fetch API using callbacks

import frontend/msg.{type Msg}
import lustre/effect.{type Effect}
import shared

// FFI declarations for JavaScript functions
@external(javascript, "./api_ffi.mjs", "patchTodo")
fn do_patch_todo(
  id: String,
  completed: Bool,
  on_success: fn(Dynamic) -> Nil,
  on_error: fn(String) -> Nil,
) -> Nil

/// Opaque type for JavaScript dynamic values
type Dynamic

/// Patch a todo's completed status
pub fn patch_todo(id: String, completed: Bool) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    do_patch_todo(
      id,
      completed,
      fn(_data) {
        // On success, create a todo with the updated status
        let item = shared.Todo(
          id: id,
          title: "",
          description: "",
          priority: "medium",
          completed: completed,
          created_at: 0,
          updated_at: 0,
        )
        dispatch(msg.ToggleTodoSuccess(item))
      },
      fn(error_msg) {
        // On error, revert to previous state
        dispatch(msg.ToggleTodoError(id, !completed, error_msg))
      },
    )
  })
}

/// Fetch all todos (placeholder)
pub fn fetch_todos() -> Effect(Msg) {
  effect.none()
}
