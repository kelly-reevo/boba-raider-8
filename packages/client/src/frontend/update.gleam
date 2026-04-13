import frontend/effects
import frontend/model.{type Model, Active, All, Completed, Model}
import frontend/msg.{type Msg}
import lustre/effect.{type Effect}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    msg.FilterChanged(filter_str) -> {
      let new_filter = case filter_str {
        "active" -> Active
        "completed" -> Completed
        _ -> All
      }
      #(Model(..model, filter: new_filter), effects.get_todos(new_filter))
    }

    msg.TodosFetched(todos) -> {
      #(Model(..model, todos: todos, loading: False), effect.none())
    }

    msg.FetchError(error) -> {
      #(Model(..model, error: error, loading: False), effect.none())
    }
  }
}
