/// State updates for the application

import frontend/effects
import frontend/model.{type Model, Model}
import frontend/msg.{type Msg}
import lustre/effect.{type Effect}

/// Main update function - handles all messages
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Load todos
    msg.LoadTodos -> {
      #(Model(..model, loading_state: model.Loading), effects.load_todos())
    }

    msg.LoadTodosOk(todos) -> {
      #(Model(..model, todos: todos, loading_state: model.Idle), effect.none())
    }

    msg.LoadTodosError(err) -> {
      #(Model(..model, loading_state: model.Error(err)), effect.none())
    }

    // Delete todo with confirmation flow
    msg.RequestDelete(id) -> {
      // Skip confirmation for simplicity - proceed directly to deletion
      #(Model(..model, loading_state: model.Loading), effects.delete_todo(id))
    }

    msg.ConfirmDelete(id) -> {
      // User confirmed deletion - call API
      #(Model(..model, loading_state: model.Loading), effects.delete_todo(id))
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
      #(Model(..model, loading_state: model.Error("Failed to delete todo"), deleting_id: option.None), effect.none())
    }
  }
}

// Import option module for None
import gleam/option
