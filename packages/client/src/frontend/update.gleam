/// State updates with comprehensive error handling

import frontend/effects
import frontend/model as model
import frontend/msg.{type Msg}
import gleam/list
import lustre/effect.{type Effect}

/// Main update function
pub fn update(m: model.AppModel, msg: Msg) -> #(model.AppModel, Effect(Msg)) {
  case msg {
    // Form input handling
    msg.FormInputChanged(value) -> {
      #(model.AppModel(..m, form_input: value), effect.none())
    }

    msg.FormSubmitted -> {
      case m.form_input {
        "" -> #(m, effect.none())
        _ -> {
          #(m, effects.create_todo(m.form_input))
        }
      }
    }

    msg.AddTodoRequest -> {
      #(m, effect.none())
    }

    // Load operations
    msg.LoadTodosRequest -> {
      #(model.AppModel(..m, is_loading: True), effects.load_todos())
    }

    msg.LoadTodosSuccess(loaded_todos) -> {
      // Clear all errors on successful load
      #(model.AppModel(
        ..m,
        todos: loaded_todos,
        is_loading: False,
        global_error: model.NoError,
        list_error: model.NoError,
      ), effect.none())
    }

    msg.LoadTodosError(_) -> {
      #(model.AppModel(
        ..m,
        is_loading: False,
        global_error: model.Error("Failed to load todos. Please refresh.", False),
      ), effect.none())
    }

    // Add operations - clear form error on success
    msg.AddTodoSuccess(item) -> {
      #(model.AppModel(
        ..m,
        todos: [item, ..m.todos],
        form_input: "",
        form_error: model.NoError,
        global_error: model.NoError,
      ), effect.none())
    }

    msg.AddTodoError(err) -> {
      #(model.AppModel(..m, form_error: model.Error(err, False)), effect.none())
    }

    // Update operations - transient errors that fade
    msg.UpdateTodoRequest(id, completed) -> {
      // Optimistically update the UI
      let updated_todos = list.map(m.todos, fn(item) {
        case item.id == id {
          True -> model.Todo(..item, completed: completed)
          False -> item
        }
      })
      #(model.AppModel(..m, todos: updated_todos), effects.update_todo(id, completed))
    }

    msg.UpdateTodoSuccess(item) -> {
      // Clear list errors on success, update with server state
      #(model.AppModel(
        ..m,
        todos: list.map(m.todos, fn(t) {
          case t.id == item.id {
            True -> item
            False -> t
          }
        }),
        list_error: model.NoError,
        transient_error_active: False,
      ), effect.none())
    }

    msg.UpdateTodoError(id, original_completed, _err) -> {
      // Revert optimistic update and show transient error
      let reverted_todos = list.map(m.todos, fn(item) {
        case item.id == id {
          True -> model.Todo(..item, completed: original_completed)
          False -> item
        }
      })
      let new_model = model.AppModel(
        ..m,
        todos: reverted_todos,
        list_error: model.Error("Update failed", True),
        transient_error_active: True,
      )
      #(new_model, effects.start_transient_error_timer())
    }

    // Delete operations - item stays in list on error
    msg.DeleteTodoRequest(id) -> {
      // Don't remove from list yet - wait for success
      #(m, effects.delete_todo(id, find_todo(m.todos, id)))
    }

    msg.DeleteTodoSuccess(id) -> {
      #(model.AppModel(
        ..m,
        todos: list.filter(m.todos, fn(t) { t.id != id }),
        list_error: model.NoError,
      ), effect.none())
    }

    msg.DeleteTodoError(_, _, _err) -> {
      // Item stays in list, show error
      #(model.AppModel(..m, list_error: model.Error("Delete failed", False)), effect.none())
    }

    // Error management
    msg.ClearTransientError -> {
      let new_list_error = case m.list_error {
        model.Error(_, True) -> model.NoError
        other -> other
      }
      #(model.AppModel(
        ..m,
        list_error: new_list_error,
        transient_error_active: False,
      ), effect.none())
    }

    msg.DismissError(container) -> {
      let new_model = case container {
        msg.ListErrorContainer -> model.AppModel(..m, list_error: model.NoError)
        msg.FormErrorContainer -> model.AppModel(..m, form_error: model.NoError)
        msg.GlobalErrorContainer -> model.AppModel(..m, global_error: model.NoError)
      }
      #(new_model, effect.none())
    }
  }
}

/// Find a todo by ID (returns a dummy if not found for type safety)
fn find_todo(todos: List(model.Todo), id: String) -> model.Todo {
  case list.find(todos, fn(t) { t.id == id }) {
    Ok(item) -> item
    Error(_) -> model.Todo(id: id, title: "", completed: False)
  }
}
