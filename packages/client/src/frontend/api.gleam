/// API client for backend communication via FFI to browser fetch

import frontend/msg.{type Msg}
import lustre/effect.{type Effect}

/// Delete a todo by ID - uses FFI to browser fetch
pub fn delete_todo(id: String) -> Effect(Msg) {
  let url = "/api/todos/" <> id

  effect.from(fn(dispatch) {
    delete_todo_js(url, fn(success) {
      case success {
        True -> {
          dispatch(msg.TodoDeleted(id))
          dispatch(msg.StopLoading(msg.DeleteLoading(id)))
        }
        False -> {
          dispatch(msg.DeleteTodoFailed(id, "Failed to delete todo"))
          dispatch(msg.StopLoading(msg.DeleteLoading(id)))
        }
      }
    })
  })
}

/// FFI to JavaScript fetch for DELETE request
@external(javascript, "../ffi.mjs", "deleteTodo")
fn delete_todo_js(url: String, callback: fn(Bool) -> Nil) -> Nil
