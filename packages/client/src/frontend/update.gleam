/// State transitions for the MVU architecture
/// Server-authoritative: user actions fire API calls, responses update state

import frontend/effects
import frontend/model.{type FilterState, type Model, Model}
import frontend/msg.{type Msg}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import lustre/effect.{type Effect}
import shared.{type Priority, type Todo}

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
    msg.UpdateFormTitle(text) -> {
      #(Model(..model, form_title: text), effect.none())
    }

    msg.UpdateFormDescription(text) -> {
      let desc_opt = case string.trim(text) {
        "" -> None
        trimmed -> Some(trimmed)
      }
      #(Model(..model, form_description: desc_opt), effect.none())
    }

    msg.UpdateFormPriority(priority_str) -> {
      #(Model(..model, form_priority: priority_str), effect.none())
    }

    // ===== Todo Creation =====
    msg.SubmitCreateTodo -> {
      // Validate form before submitting
      case validate_create_form(model) {
        Ok(_) -> {
          // Clear form and set loading
          let new_model = Model(
            ..model,
            form_title: "",
            form_description: None,
            form_priority: "medium",
            loading: True,
          )
          let effect = effects.create_todo(
            model.form_title,
            model.form_description,
            model.form_priority,
          )
          #(new_model, effect)
        }
        Error(error_msg) -> {
          // Validation failed - show error and preserve form values
          #(Model(..model, error: error_msg), effect.none())
        }
      }
    }

    msg.CreateTodoResponse(Ok(created_todo)) -> {
      // Add new todo to list, clear loading, clear error, and reload todos
      let new_todos = [created_todo, ..model.todos]
      let filter_opt = filter_state_to_string(model.filter)
      #(Model(..model, todos: new_todos, loading: False, error: ""), effects.fetch_todos(filter_opt))
    }

    msg.CreateTodoResponse(Error(http_error)) -> {
      let error_msg = case http_error {
        msg.NetworkError -> "Network error. Please check your connection."
        _ -> "Failed to create todo. Please try again."
      }
      // Preserve form values on error
      #(Model(..model, loading: False, error: error_msg), effect.none())
    }

    // ===== Todo Toggle =====
    msg.ToggleTodo(id, completed) -> {
      // Optimistic UI update - update local state immediately
      let new_todos = list.map(model.todos, fn(t) {
        case t.id == id {
          True -> shared.Todo(..t, completed: completed)
          False -> t
        }
      })
      let optimistic_model = Model(..model, todos: new_todos, loading: True)
      let effect = effects.toggle_todo(id, completed)
      #(optimistic_model, effect)
    }

    msg.ToggleResult(Ok(_updated_todo)) -> {
      // Server confirmed - refresh the full list to ensure consistency
      let filter_opt = filter_state_to_string(model.filter)
      #(Model(..model, loading: False), effects.fetch_todos(filter_opt))
    }

    msg.ToggleResult(Error(http_error)) -> {
      let error_msg = msg.http_error_to_string(http_error)
      // Revert optimistic update by fetching current server state
      let filter_opt = filter_state_to_string(model.filter)
      let refresh_effect = effects.fetch_todos(filter_opt)
      #(Model(..model, loading: False, error: error_msg), refresh_effect)
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
/// Returns Ok(Nil) if valid, Error(String) with error message if invalid
fn validate_create_form(model: Model) -> Result(Nil, String) {
  // Check for empty title
  case string.trim(model.form_title) {
    "" -> Error("Title is required")
    trimmed -> {
      // Check title max length (200 chars)
      case string.length(trimmed) > 200 {
        True -> Error("Title must be 200 characters or less")
        False -> Ok(Nil)
      }
    }
  }
}
