/// Application update logic - state transitions and side effects

import frontend/effects
import frontend/model.{type Model, Loading, Loaded}
import frontend/msg.{type Msg}
import gleam/string
import lustre/effect.{type Effect}

/// Main update function - handles all message types
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Data loading messages
    msg.FetchTodos -> #(
      Model(..model, data_state: Loading),
      effects.fetch_todos()
    )

    msg.TodosLoaded(todos) -> #(
      Model(..model, todos: todos, data_state: Loaded),
      effect.none()
    )

    msg.TodosLoadError(error) -> #(
      Model(..model, data_state: model.Error(error)),
      effect.none()
    )

    msg.RetryFetch -> #(
      Model(..model, data_state: Loading),
      effects.fetch_todos()
    )

    msg.SetFilter(filter) -> #(
      Model(..model, filter: filter),
      effect.none()
    )

    // Form field updates - update model state directly
    msg.TitleChanged(title) -> #(model.update_form_title(model, title), effect.none())
    msg.DescriptionChanged(desc) -> #(model.update_form_description(model, desc), effect.none())
    msg.PriorityChanged(priority) -> #(model.update_form_priority(model, priority), effect.none())

    // Form submission - validate and make API call
    msg.SubmitForm -> {
      let title = string.trim(model.form.title)
      case string.is_empty(title) {
        True -> #(model.set_error(model, "Title is required"), effect.none())
        False -> {
          let description = string.trim(model.form.description)
          let priority = model.form.priority
          #(model.set_submitting(model), effects.create_todo_and_refresh(title, description, priority))
        }
      }
    }

    // Create succeeded - clear form and trigger list refresh
    msg.CreateTodoSucceeded(_todo) -> {
      let cleared_model = model.reset_form(model)
      #(cleared_model, effect.from(fn(dispatch) {
        dispatch(msg.RefreshTodos)
      }))
    }

    // Create failed - show error, keep form values
    msg.CreateTodoFailed(error_msg) -> {
      #(model.set_error(model, error_msg), effect.none())
    }

    // Refresh todos list - fetch from API
    msg.RefreshTodos -> {
      #(model, effects.fetch_todos())
    }

    // Todos refreshed - update model with new list
    msg.TodosRefreshed(todos) -> {
      #(model.update_todos(model, todos), effect.none())
    }

    // Todos refresh failed - show error
    msg.TodosRefreshFailed(error_msg) -> {
      #(model.set_error(model, error_msg), effect.none())
    }

    // Delete todo flow
    msg.DeleteTodo(id) -> {
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
    msg.Deleted(id) -> {
      #(model.remove_todo(model, id), effect.none())
    }

    // Delete failed - show error, clear deleting state
    msg.DeleteError(message) -> {
      #(model.set_error(model, message), effect.none())
    }

    // Dismiss error banner
    msg.DismissError -> {
      #(model.clear_error(model), effect.none())
    }
  }
}

/// Show browser confirmation dialog
/// Returns true if user confirms deletion
@external(javascript, "./update_ffi.mjs", "confirm_delete")
fn confirm_delete() -> Bool
