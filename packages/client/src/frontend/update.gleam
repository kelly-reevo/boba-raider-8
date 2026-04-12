/// Update functions for todo list operations

import frontend/effects
import frontend/model.{
  type ErrorType, type Model, ErrorInfo, Model, Network, Server, Validation,
}
import frontend/msg.{type Msg}
import gleam/int
import gleam/list
import gleam/option
import gleam/string
import lustre/effect.{type Effect}
import shared

/// Convert error type string to ErrorType
fn error_type_from_string(type_str: String) -> ErrorType {
  case string.lowercase(type_str) {
    "network" -> Network
    "validation" -> Validation
    _ -> Server
  }
}

/// Generate unique error ID
fn generate_error_id(count: Int, type_str: String) -> String {
  "error-" <> int.to_string(count) <> "-" <> type_str
}

/// Main update function - handles all messages
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Initial load
    msg.LoadTodos -> #(
      Model(..model, loading: model.Loading),
      effects.fetch_todos(),
    )

    // Todos loaded from API (legacy format)
    msg.TodosLoaded(result) -> {
      case result {
        Ok(todos) -> #(
          Model(todos: todos, loading: model.Success, error: "", deleting_id: model.deleting_id, errors: model.errors),
          effect.none(),
        )
        Error(err) -> #(
          Model(..model, loading: model.Error(err), error: err),
          effect.none(),
        )
      }
    }

    // Todos loaded successfully (new format)
    msg.LoadTodosOk(todos) -> {
      #(Model(todos: todos, loading: model.Success, error: "", deleting_id: model.deleting_id, errors: model.errors), effect.none())
    }

    // Error loading todos
    msg.LoadTodosError(err) -> {
      #(Model(..model, loading: model.Error(err), error: err), effect.none())
    }

    // New todo created - add to list
    msg.TodoCreated(new_todo) -> #(
      Model(..model, todos: [new_todo, ..model.todos]),
      effect.none(),
    )

    // Todo updated - replace in list
    msg.TodoUpdated(updated_todo) -> {
      let new_todos = list.map(model.todos, fn(t) {
        case t.id == updated_todo.id {
          True -> updated_todo
          False -> t
        }
      })
      #(Model(..model, todos: new_todos), effect.none())
    }

    // Todo deleted - remove from list (legacy)
    msg.TodoDeleted(id) -> {
      let new_todos = list.filter(model.todos, fn(t) { t.id != id })
      #(Model(..model, todos: new_todos, deleting_id: option.None), effect.none())
    }

    // Delete todo with confirmation flow
    msg.RequestDelete(id) -> {
      // Skip confirmation for simplicity - proceed directly to deletion
      #(Model(..model, loading: model.Loading, deleting_id: Some(id)), effects.delete_todo(id))
    }

    msg.ConfirmDelete(id) -> {
      // User confirmed deletion - call API
      #(Model(..model, loading: model.Loading), effects.delete_todo(id))
    }

    msg.CancelDelete -> {
      // User cancelled deletion
      #(Model(..model, deleting_id: option.None), effect.none())
    }

    msg.DeleteTodoOk(id) -> {
      // Successfully deleted - remove from model
      #(model.remove_todo(model, id), effect.none())
    }

    msg.DeleteTodoError(_err) -> {
      // Deletion failed - show error, clear deleting state
      #(Model(..model, loading: model.Error("Failed to delete todo"), deleting_id: option.None), effect.none())
    }

    // Toggle todo completion state locally (API call handled separately)
    msg.ToggleTodoComplete(id, completed) -> {
      let new_todos = list.map(model.todos, fn(t) {
        case t.id == id {
          True -> shared.Todo(..t, completed: completed)
          False -> t
        }
      })
      #(Model(..model, todos: new_todos), effect.none())
    }

    // Delete todo triggered by user (API call handled separately)
    msg.DeleteTodo(id) -> {
      let new_todos = list.filter(model.todos, fn(t) { t.id != id })
      #(Model(..model, todos: new_todos), effect.none())
    }

    // Error display handling
    msg.ShowError(message, type_str) -> {
      let error_type = error_type_from_string(type_str)
      let error_id = generate_error_id(list.length(model.errors), type_str)
      let new_error = ErrorInfo(id: error_id, message: message, type_: error_type)
      let new_model = Model(..model, errors: [new_error, ..model.errors])

      // Auto-dismiss after 5 seconds
      let auto_dismiss_effect =
        effect.from(fn(dispatch) {
          let _ = set_timeout(5000, fn() {
            dispatch(msg.AutoDismissError(error_id))
          })
          Nil
        })

      #(new_model, auto_dismiss_effect)
    }

    msg.DismissError(error_id) -> {
      #(model.dismiss_error(model, error_id), effect.none())
    }

    msg.AutoDismissError(error_id) -> {
      #(model.dismiss_error(model, error_id), effect.none())
    }
  }
}

// FFI for setTimeout
@external(javascript, "../client_ffi.mjs", "set_timeout")
fn set_timeout(_ms: Int, _callback: fn() -> Nil) -> Nil {
  Nil
}
