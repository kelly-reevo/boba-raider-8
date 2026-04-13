import frontend/msg.{type Msg, Deleted, DeleteError}
import lustre/effect.{type Effect}

/// Delete a todo by ID
/// Calls DELETE /api/todos/:id
/// On 204: returns Deleted message with the id
/// On error: returns DeleteError with message
pub fn delete_todo(id: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // Use JavaScript fetch API
    do_delete_request(id, fn(status) {
      case status {
        204 -> dispatch(Deleted(id))
        404 -> dispatch(DeleteError("Todo not found"))
        _ -> dispatch(DeleteError("Failed to delete todo. Please try again."))
      }
    })
  })
}

/// Perform DELETE request via JavaScript FFI
@external(javascript, "./delete_effect_ffi.mjs", "delete_request")
fn do_delete_request(id: String, callback: fn(Int) -> Nil) -> Nil
