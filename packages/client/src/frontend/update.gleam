/// State update logic

import frontend/effects
import frontend/model.{type Model, Model}
import frontend/msg.{type Msg}
import gleam/list
import lustre/effect.{type Effect}
import shared.{Todo}

/// Update function handling all message types
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Toggle todo completion - optimistic update
    msg.ToggleTodo(id, completed) -> {
      let updated_todos =
        list.map(model.todos, fn(item) {
          case item.id == id {
            True -> Todo(..item, completed: completed)
            False -> item
          }
        })
      let new_model = Model(
        ..model,
        todos: updated_todos,
        toggling_id: id,
        error: "",
      )
      #(new_model, effects.patch_todo(id, completed))
    }

    // Toggle success - update with server response
    msg.ToggleTodoSuccess(item) -> {
      let updated_todos =
        list.map(model.todos, fn(it) {
          case it.id == item.id {
            True -> item
            False -> it
          }
        })
      #(Model(..model, todos: updated_todos, toggling_id: ""), effect.none())
    }

    // Toggle error - revert to previous state and show error
    msg.ToggleTodoError(id, previous_state, error) -> {
      let reverted_todos =
        list.map(model.todos, fn(item) {
          case item.id == id {
            True -> Todo(..item, completed: previous_state)
            False -> item
          }
        })
      #(Model(..model, todos: reverted_todos, toggling_id: "", error: error), effect.none())
    }

    // Data loading (placeholder)
    msg.LoadTodos -> #(model, effect.none())
    msg.LoadTodosSuccess(items) -> #(Model(..model, todos: items), effect.none())
    msg.LoadTodosError(error) -> #(Model(..model, error: error), effect.none())
  }
}
