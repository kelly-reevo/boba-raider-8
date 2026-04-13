/// Application update logic - state transitions and side effects

import frontend/effects
import frontend/model.{type Model, Model, Loading, Loaded, All, Active, Completed}
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

    // Filter messages
    msg.SetFilter(filter) -> #(
      Model(..model, filter: filter),
      effects.get_todos(filter)
    )

    msg.FilterChanged(filter_str) -> {
      let new_filter = case filter_str {
        "active" -> Active
        "completed" -> Completed
        _ -> All
      }
      #(Model(..model, filter: new_filter), effects.get_todos(new_filter))
    }

    msg.TodosFetched(todos) -> #(
      Model(..model, todos: todos, data_state: Loaded),
      effect.none()
    )

    msg.FetchError(error) -> #(
      Model(..model, data_state: model.Error(error)),
      effect.none()
    )

    // Form field updates
    msg.TitleChanged(title) -> #(model.update_form_title(model, title), effect.none())
    msg.DescriptionChanged(desc) -> #(model.update_form_description(model, desc), effect.none())
    msg.PriorityChanged(priority) -> #(model.update_form_priority(model, priority), effect.none())

    // Form submission
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

    msg.CreateTodoSucceeded(_todo) -> {
      let cleared_model = model.reset_form(model)
      #(cleared_model, effect.from(fn(dispatch) {
        dispatch(msg.RefreshTodos)
      }))
    }

    msg.CreateTodoFailed(error_msg) -> {
      #(model.set_error(model, error_msg), effect.none())
    }

    msg.RefreshTodos -> {
      #(model, effects.fetch_todos())
    }

    msg.TodosRefreshed(todos) -> {
      #(model.update_todos(model, todos), effect.none())
    }

    msg.TodosRefreshFailed(error_msg) -> {
      #(model.set_error(model, error_msg), effect.none())
    }

    // Delete todo flow
    msg.DeleteTodo(id) -> {
      case confirm_delete() {
        True -> {
          #(model.set_deleting(model, id), effects.delete_todo(id))
        }
        False -> {
          #(model, effect.none())
        }
      }
    }

    msg.Deleted(id) -> {
      #(model.remove_todo(model, id), effect.none())
    }

    msg.DeleteError(message) -> {
      #(model.set_error(model, message), effect.none())
    }

    // Toggle completion - optimistically update UI, then call API
    msg.ToggleTodo(id, completed) -> {
      let new_model = model.update_todo_completed(model, id, completed)
      #(new_model, effects.patch_todo(id, completed))
    }

    // API success: Update todo with server response
    msg.TodoToggledOk(toggled_item) -> {
      #(model.update_todo(model, toggled_item), effect.none())
    }

    // API error: Revert to original state
    msg.TodoToggledError(id, original_completed) -> {
      let new_model = model.update_todo_completed(model, id, original_completed)
      #(Model(..new_model, error: "Failed to update todo"), effect.none())
    }

    // Error handling
    msg.DismissError -> {
      #(model.clear_error(model), effect.none())
    }

    msg.SetError(message) -> {
      #(model.set_error(model, message), effect.none())
    }
  }
}

/// Show browser confirmation dialog
@external(javascript, "./update_ffi.mjs", "confirm_delete")
fn confirm_delete() -> Bool
