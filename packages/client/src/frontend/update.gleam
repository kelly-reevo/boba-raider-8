/// Update functions for todo list operations

import frontend/effects
import frontend/model.{type Model, Model}
import frontend/msg.{type Msg}
import gleam/list
import gleam/option
import lustre/effect.{type Effect}
import shared

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
          Model(todos: todos, loading: model.Success, error: "", deleting_id: model.deleting_id),
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
      #(Model(todos: todos, loading: model.Success, error: "", deleting_id: model.deleting_id), effect.none())
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
  }
}
