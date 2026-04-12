/// Update function for application state transitions

import frontend/effects
import frontend/model.{type Model, Idle, Loading, Success, Error as LoadingError}
import frontend/msg.{type Msg}
import gleam/list
import gleam/option.{None, Some}
import lustre/effect.{type Effect}
import shared.{type Todo}

/// Handle messages and update model
pub fn update(m: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Counter messages (legacy)
    msg.Increment -> #(model.increment(m), effect.none())
    msg.Decrement -> #(model.decrement(m), effect.none())
    msg.Reset -> #(model.reset(m), effect.none())

    // Todo list messages
    msg.LoadTodos -> {
      let new_model = model.Model(..m, loading_state: Loading)
      #(new_model, effects.fetch_todos())
    }

    msg.TodosLoaded(result) -> {
      case result {
        Ok(todos) -> {
          let new_model = model.Model(
            ..m,
            todos: todos,
            loading_state: Success,
          )
          #(new_model, effect.none())
        }
        Error(err) -> {
          let new_model = model.Model(
            ..m,
            loading_state: LoadingError(err),
            error: err,
          )
          #(new_model, effect.none())
        }
      }
    }

    msg.ToggleTodo(todo_id) -> {
      let updated_todos = list.map(m.todos, fn(item) {
        case item.id == todo_id {
          True -> shared.Todo(..item, completed: !item.completed)
          False -> item
        }
      })
      #(model.Model(..m, todos: updated_todos), effect.none())
    }

    msg.DeleteTodo(todo_id) -> {
      let filtered_todos = list.filter(m.todos, fn(item) {
        item.id != todo_id
      })
      #(model.Model(..m, todos: filtered_todos), effect.none())
    }
  }
}
