/// State transitions for the MVU architecture
/// Server-authoritative: user actions fire API calls, responses update state

import frontend/effects
import frontend/model.{type FilterState, type Model, Model}
import frontend/msg.{type Msg}
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/effect.{type Effect}
import shared.{type Todo}

/// No-op effect for testing
pub fn none() -> Effect(Msg) {
  effect.none()
}

/// Main update function handling all message types
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Legacy counter messages (backward compatibility)
    msg.Increment -> #(model, effects.post_increment())
    msg.Decrement -> #(model, effects.post_decrement())
    msg.Reset -> #(model, effects.post_reset())
    msg.GotCounter(Ok(_)) -> #(model, effect.none())
    msg.GotCounter(Error(_)) -> #(model, effect.none())

    // ===== Todo Loading =====
    msg.LoadTodos -> {
      let filter_opt = filter_state_to_string(model.filter)
      #(Model(..model, loading: True), effects.fetch_todos(filter_opt))
    }

    msg.TodosLoaded(Ok(todos)) -> {
      #(Model(..model, todos: todos, loading: False, error: ""), effect.none())
    }

    msg.TodosLoaded(Error(http_error)) -> {
      let error_msg = msg.http_error_to_string(http_error)
      #(Model(..model, loading: False, error: error_msg), effect.none())
    }

    // ===== Filter State =====
    msg.SetFilter(filter) -> {
      let filter_opt = filter_state_to_string(filter)
      #(Model(..model, filter: filter, loading: True), effects.fetch_todos(filter_opt))
    }

    // ===== Form Field Updates (local state only) =====
    msg.SetFormTitle(text) -> {
      #(Model(..model, form_title: text), effect.none())
    }

    msg.SetFormDescription(text) -> {
      #(Model(..model, form_description: text), effect.none())
    }

    msg.SetFormPriority(priority) -> {
      #(Model(..model, form_priority: priority), effect.none())
    }

    // ===== Todo Creation =====
    msg.SubmitCreateTodo -> {
      // Validate form before submitting
      case validate_create_form(model) {
        True -> {
          // Clear form and set loading
          let new_model = Model(
            ..model,
            form_title: "",
            form_description: "",
            form_priority: shared.Medium,
            loading: True,
          )
          let effect = effects.create_todo(
            model.form_title,
            model.form_description,
            model.form_priority,
          )
          #(new_model, effect)
        }
        False -> {
          // Validation failed - show error
          #(Model(..model, error: "Title is required"), effect.none())
        }
      }
    }

    msg.CreateTodoResult(Ok(created_todo)) -> {
      // Add new todo to list and clear loading
      let new_todos = [created_todo, ..model.todos]
      #(Model(..model, todos: new_todos, loading: False, error: ""), effect.none())
    }

    msg.CreateTodoResult(Error(http_error)) -> {
      let error_msg = msg.http_error_to_string(http_error)
      #(Model(..model, loading: False, error: error_msg), effect.none())
    }

    // ===== Todo Toggle =====
    msg.ToggleTodo(id, completed) -> {
      // Don't optimistically update - wait for server confirmation
      #(Model(..model, loading: True), effects.toggle_todo(id, completed))
    }

    msg.ToggleResult(Ok(updated_todo)) -> {
      // Server confirmed - update the specific todo in the list
      let new_todos = list.map(model.todos, fn(t) {
        case t.id == updated_todo.id {
          True -> updated_todo
          False -> t
        }
      })
      #(Model(..model, todos: new_todos, loading: False, error: ""), effect.none())
    }

    msg.ToggleResult(Error(_http_error)) -> {
      // Revert by keeping original model state, show error
      #(Model(..model, loading: False, error: "Failed to toggle todo. Please try again."), effect.none())
    }

    msg.GotToggleResult(Ok(updated_todo)) -> {
      // Server confirmed - update the specific todo in the list
      let new_todos = list.map(model.todos, fn(t) {
        case t.id == updated_todo.id {
          True -> updated_todo
          False -> t
        }
      })
      #(Model(..model, todos: new_todos, loading: False, error: ""), effect.none())
    }

    msg.GotToggleResult(Error(_http_error)) -> {
      // Revert by keeping original model state, show error
      #(Model(..model, loading: False, error: "Failed to toggle todo. Please try again."), effect.none())
    }

    // ===== Todo Deletion =====
    msg.DeleteTodo(id) -> {
      let effect = effects.delete_todo(id)
      #(Model(..model, loading: True), effect)
    }

    msg.DeleteResult(Ok(deleted_id)) -> {
      // Remove from local list and clear loading
      let new_todos = list.filter(model.todos, fn(t) { t.id != deleted_id })
      #(Model(..model, todos: new_todos, loading: False, error: ""), effect.none())
    }

    msg.DeleteResult(Error(http_error)) -> {
      let error_msg = msg.http_error_to_string(http_error)
      // Refresh from server to ensure consistency
      let filter_opt = filter_state_to_string(model.filter)
      let refresh_effect = effects.fetch_todos(filter_opt)
      #(Model(..model, loading: False, error: error_msg), refresh_effect)
    }
  }
}

/// Convert FilterState to optional query parameter
fn filter_state_to_string(filter: FilterState) -> Option(String) {
  case filter {
    model.All -> None
    model.Active -> Some("active")
    model.Completed -> Some("completed")
  }
}

/// Validate create form has required fields
fn validate_create_form(model: Model) -> Bool {
  case model.form_title {
    "" -> False
    _ -> True
  }
}
