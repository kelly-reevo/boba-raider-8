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

    // Delete item initiated - set loading and make API call
    msg.DeleteTodo(id) -> #(
      Model(..model, loading: True, error: ""),
      effects.delete_todo(id),
    )

    // Delete successful - remove from model.todos
    msg.DeleteTodoSuccess(id) -> #(
      Model(
        todos: list.filter(model.todos, fn(item) { item.id != id }),
        loading: False,
        error: "",
        toggling_id: model.toggling_id,
      ),
      effect.none(),
    )

    // Delete error - show error message, keep todos
    msg.DeleteTodoError(error_msg) -> #(
      Model(..model, loading: False, error: error_msg),
      effect.none(),
    )

    // Data loading
    msg.LoadTodos -> #(model, effects.fetch_todos())
    msg.LoadTodosSuccess(items) -> #(Model(..model, todos: items), effect.none())
    msg.LoadTodosError(error) -> #(Model(..model, error: error), effect.none())
    msg.TodosLoaded(todos) -> #(Model(..model, todos: todos, loading: False), effect.none())
    msg.TodosLoadError(error_msg) -> #(Model(..model, error: error_msg, loading: False), effect.none())
  }
}
