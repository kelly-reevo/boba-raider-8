import frontend/effects
import frontend/model.{type Model}
import frontend/msg.{type Msg, DeleteTodo, Deleted, DeleteError, DismissError}
import lustre/effect.{type Effect}

/// Main update function - handles all message types
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // User clicked delete button - trigger confirmation and API call
    DeleteTodo(id) -> {
      // Optional confirmation dialog
      case confirm_delete() {
        True -> {
          // User confirmed - mark as deleting and send request
          #(model.set_deleting(model, id), effects.delete_todo(id))
        }
        False -> {
          // User cancelled - no change
          #(model, effect.none())
        }
      }
    }

    // Successfully deleted - remove from model
    Deleted(id) -> {
      #(model.remove_todo(model, id), effect.none())
    }

    // Delete failed - show error, clear deleting state
    DeleteError(message) -> {
      #(model.set_error(model, message), effect.none())
    }

    // Dismiss error banner
    DismissError -> {
      #(model.clear_error(model), effect.none())
    }
  }
}

/// Show browser confirmation dialog
/// Returns true if user confirms deletion
@external(javascript, "./update_ffi.mjs", "confirm_delete")
fn confirm_delete() -> Bool
