/// State updates

import frontend/effects
import frontend/model.{type Model, Model}
import frontend/msg.{type Msg}
import lustre/effect.{type Effect}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Counter messages (existing)
    msg.Increment -> #(Model(..model, count: model.count + 1), effect.none())
    msg.Decrement -> #(Model(..model, count: model.count - 1), effect.none())
    msg.Reset -> #(Model(..model, count: 0), effect.none())

    // Filter messages
    msg.FilterChanged(filter) -> #(
      Model(..model, current_filter: filter, loading: True, error: ""),
      effects.list_todos(filter),
    )

    msg.TodosLoaded(result) -> {
      case result {
        Ok(todos) -> #(Model(..model, todos: todos, loading: False, error: ""), effect.none())
        Error(err) -> #(Model(..model, loading: False, error: err), effect.none())
      }
    }
  }
}
