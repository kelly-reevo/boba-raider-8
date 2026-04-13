import frontend/effects
import frontend/model.{type Model, Model}
import frontend/msg.{type Msg}
import gleam/list
import lustre/effect.{type Effect}
import shared.{Todo}

/// Main update function handling all messages
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Fetch todos
    msg.FetchTodos -> #(
      Model(..model, loading: True, error: ""),
      effects.fetch_todos(),
    )
    msg.FetchTodosSuccess(todos) -> #(
      Model(todos: todos, loading: False, error: "", toggling_id: model.toggling_id),
      effect.none(),
    )
    msg.FetchTodosError(error) -> #(
      Model(..model, loading: False, error: error),
      effect.none(),
    )

    // Alternative loading messages
    msg.LoadTodos -> #(model, effects.fetch_todos())
    msg.TodosLoaded(todos) -> #(Model(..model, todos: todos, loading: False), effect.none())
    msg.TodosLoadFailed(error) -> #(Model(..model, loading: False, error: error), effect.none())

    // Toggle todo with optimistic update
    msg.ToggleTodo(id, completed) -> {
      let updated_todos = list.map(model.todos, fn(item) {
        case item.id == id {
          True -> Todo(..item, completed: completed)
          False -> item
        }
      })
      #(Model(..model, todos: updated_todos, toggling_id: id), effects.patch_todo(id, completed))
    }
    msg.ToggleTodoSuccess(item) -> {
      let updated_todos = list.map(model.todos, fn(it) {
        case it.id == item.id {
          True -> item
          False -> it
        }
      })
      #(Model(..model, todos: updated_todos, toggling_id: ""), effect.none())
    }
    msg.ToggleTodoError(id, previous_state, error) -> {
      let reverted_todos = list.map(model.todos, fn(item) {
        case item.id == id {
          True -> Todo(..item, completed: previous_state)
          False -> item
        }
      })
      #(Model(..model, todos: reverted_todos, toggling_id: "", error: error), effect.none())
    }
    msg.TodoUpdated(updated) -> {
      let new_todos = list.map(model.todos, fn(t) {
        case t.id == updated.id {
          True -> updated
          False -> t
        }
      })
      #(Model(..model, todos: new_todos, toggling_id: ""), effect.none())
    }
    msg.TodoUpdateFailed(error) -> #(Model(..model, error: error, toggling_id: ""), effect.none())

    // Delete todo
    msg.DeleteTodo(id) -> #(model, effects.delete_todo(id))
    msg.TodoDeleted(id) -> {
      let new_todos = list.filter(model.todos, fn(t) { t.id != id })
      #(Model(..model, todos: new_todos), effect.none())
    }
    msg.TodoDeleteFailed(error) -> #(Model(..model, error: error), effect.none())
  }
}
