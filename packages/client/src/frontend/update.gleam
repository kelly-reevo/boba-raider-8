import frontend/effects
import frontend/model.{type Model, Model}
import frontend/msg.{type Msg, ToggleTodo, TodoToggledOk, TodoToggledError, TodosLoaded, SetError}
import gleam/list
import lustre/effect.{type Effect}
import shared.{type Todo, Todo}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // ToggleTodo: Optimistically update UI, then call API
    msg.ToggleTodo(id, completed) -> {
      let new_todos = list.map(model.todos, fn(item) {
        case item.id == id {
          True -> Todo(..item, completed: completed)
          False -> item
        }
      })
      #(Model(..model, todos: new_todos), effects.patch_todo(id, completed))
    }

    // API success: Update todo with server response
    msg.TodoToggledOk(toggled_item) -> {
      let new_todos = list.map(model.todos, fn(item) {
        case item.id == toggled_item.id {
          True -> toggled_item
          False -> item
        }
      })
      #(Model(..model, todos: new_todos), effect.none())
    }

    // Initial todos loaded
    msg.TodosLoaded(loaded_todos) -> {
      #(Model(..model, todos: loaded_todos), effect.none())
    }

    // API error: Revert to original state and show error
    msg.TodoToggledError(id, original_completed) -> {
      let reverted_todos = list.map(model.todos, fn(item) {
        case item.id == id {
          True -> Todo(..item, completed: original_completed)
          False -> item
        }
      })
      #(Model(..model, todos: reverted_todos, error: "Failed to update todo"), effect.none())
    }

    // Set error message
    msg.SetError(message) -> {
      #(Model(..model, error: message), effect.none())
    }
  }
}
