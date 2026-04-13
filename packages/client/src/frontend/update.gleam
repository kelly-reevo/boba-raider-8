import frontend/effects
import frontend/model.{type Model, Model}
import frontend/msg.{type Msg}
import lustre/effect.{type Effect}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    msg.FetchTodos -> #(
      Model(..model, loading: True, error: ""),
      effects.fetch_todos(),
    )
    msg.FetchTodosSuccess(todos) -> #(
      Model(todos: todos, loading: False, error: ""),
      effect.none(),
    )
    msg.FetchTodosError(error) -> #(
      Model(..model, loading: False, error: error),
      effect.none(),
    )
    msg.ToggleTodo(_id, _completed) -> #(model, effect.none())
    msg.DeleteTodo(_id) -> #(model, effect.none())
  }
}
