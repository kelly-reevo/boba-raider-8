/// Update functions for todo list operations

import frontend/effects
import frontend/model
import frontend/msg.{type Msg}
import gleam/list
import lustre/effect.{type Effect}
import shared

/// Main update function
pub fn update(model: model.Model, msg: Msg) -> #(model.Model, Effect(Msg)) {
  case msg {
    // Initial load
    msg.LoadTodos -> #(
      model.Model(..model, loading: model.Loading),
      effects.fetch_todos(),
    )

    // Todos loaded from API
    msg.TodosLoaded(result) -> {
      case result {
        Ok(todos) -> #(
          model.Model(todos: todos, loading: model.Success, error: ""),
          effect.none(),
        )
        Error(err) -> #(
          model.Model(..model, loading: model.Error(err), error: err),
          effect.none(),
        )
      }
    }

    // New todo created - add to list
    msg.TodoCreated(new_todo) -> #(
      model.Model(..model, todos: [new_todo, ..model.todos]),
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
      #(model.Model(..model, todos: new_todos), effect.none())
    }

    // Todo deleted - remove from list
    msg.TodoDeleted(id) -> {
      let new_todos = list.filter(model.todos, fn(t) { t.id != id })
      #(model.Model(..model, todos: new_todos), effect.none())
    }

    // Toggle todo completion state locally (API call handled separately)
    msg.ToggleTodoComplete(id, completed) -> {
      let new_todos = list.map(model.todos, fn(t) {
        case t.id == id {
          True -> shared.Todo(..t, completed: completed)
          False -> t
        }
      })
      #(model.Model(..model, todos: new_todos), effect.none())
    }

    // Delete todo triggered by user (API call handled separately)
    msg.DeleteTodo(id) -> {
      let new_todos = list.filter(model.todos, fn(t) { t.id != id })
      #(model.Model(..model, todos: new_todos), effect.none())
    }
  }
}
