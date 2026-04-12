/// Application update logic with loading states

import frontend/effects
import frontend/model.{type Model, Model, add_loading, clear_error, is_creating, is_deleting, is_updating, remove_loading, set_error}
import frontend/msg.{type Msg, ClearError, ClearForm, CreateTodo, CreateTodoFailed, DeleteTodo, DeleteTodoFailed, LoadTodos, LoadTodosFailed, StartLoading, StopLoading, SubmitForm, ToggleTodo, TodoCreated, TodoDeleted, TodosLoaded, TodoUpdated, UpdateDescription, UpdateTitle, UpdateTodoFailed}
import gleam/list
import lustre/effect.{type Effect}
import shared.{type Todo, Todo}

/// Main update function handling all messages
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Form input updates
    UpdateTitle(title) -> {
      #(Model(..model, form_title: title), effect.none())
    }

    UpdateDescription(desc) -> {
      #(Model(..model, form_description: desc), effect.none())
    }

    ClearForm -> {
      #(Model(..model, form_title: "", form_description: ""), effect.none())
    }

    // Form submission - trigger create if not already creating
    SubmitForm -> {
      case is_creating(model) || model.form_title == "" {
        True -> #(model, effect.none())
        False -> {
          // Clear any existing error, then create
          let model_with_cleared_error = clear_error(model)
          #(model_with_cleared_error, effects.create_todo(model.form_title, model.form_description))
        }
      }
    }

    // Load todos list
    LoadTodos -> {
      #(clear_error(model), effects.load_todos())
    }

    TodosLoaded(todos) -> {
      #(Model(..model, todos: todos), effect.none())
    }

    LoadTodosFailed(error_msg) -> {
      #(set_error(model, error_msg), effect.none())
    }

    // Create todo operations
    CreateTodo -> {
      case is_creating(model) || model.form_title == "" {
        True -> #(model, effect.none())
        False -> {
          #(clear_error(model), effects.create_todo(model.form_title, model.form_description))
        }
      }
    }

    TodoCreated(new_todo) -> {
      let updated_todos = [new_todo, ..model.todos]
      #(Model(..model, todos: updated_todos, form_title: "", form_description: ""), effect.none())
    }

    CreateTodoFailed(error_msg) -> {
      #(set_error(model, error_msg), effect.none())
    }

    // Toggle todo operations
    ToggleTodo(todo_id, new_completed) -> {
      // Check if already updating this todo
      case is_updating(model, todo_id) {
        True -> #(model, effect.none())
        False -> {
          #(clear_error(model), effects.update_todo(todo_id, new_completed))
        }
      }
    }

    TodoUpdated(updated_todo) -> {
      let updated_todos = list.map(model.todos, fn(t) {
        case t.id == updated_todo.id {
          True -> updated_todo
          False -> t
        }
      })
      #(Model(..model, todos: updated_todos), effect.none())
    }

    UpdateTodoFailed(todo_id, original_completed, error_msg) -> {
      // Revert the todo state on error
      let reverted_todos = list.map(model.todos, fn(t) {
        case t.id == todo_id {
          True -> Todo(..t, completed: original_completed)
          False -> t
        }
      })
      #(set_error(Model(..model, todos: reverted_todos), error_msg), effect.none())
    }

    // Delete todo operations
    DeleteTodo(todo_id) -> {
      // Check if already deleting this todo
      case is_deleting(model, todo_id) {
        True -> #(model, effect.none())
        False -> {
          #(clear_error(model), effects.delete_todo(todo_id))
        }
      }
    }

    TodoDeleted(todo_id) -> {
      let filtered_todos = list.filter(model.todos, fn(t) { t.id != todo_id })
      #(Model(..model, todos: filtered_todos), effect.none())
    }

    DeleteTodoFailed(_, error_msg) -> {
      #(set_error(model, error_msg), effect.none())
    }

    // Loading state management
    StartLoading(operation) -> {
      #(add_loading(model, operation), effect.none())
    }

    StopLoading(operation) -> {
      #(remove_loading(model, operation), effect.none())
    }

    ClearError -> {
      #(clear_error(model), effect.none())
    }
  }
}
