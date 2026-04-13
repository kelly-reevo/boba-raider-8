/// Application update logic - state transitions and side effects

import frontend/effects
import frontend/model.{type Model}
import frontend/msg.{type Msg}
import gleam/string
import lustre/effect.{type Effect}

/// Main update function - handles all messages
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
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
          #(model.set_loading(model), effects.create_todo_and_refresh(title, description, priority))
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
  }
}
