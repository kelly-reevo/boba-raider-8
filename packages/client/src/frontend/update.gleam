import frontend/effects
import frontend/model.{type Model, Loading, Success, Error as FetchError}
import frontend/msg.{type Msg}
import lustre/effect.{type Effect}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    msg.FetchTodos -> {
      #(model.Model(..model, status: Loading), effects.fetch_todos())
    }
    msg.GotTodos(result) -> {
      case result {
        Ok(todos) -> {
          #(model.Model(..model, todos: todos, status: Success), effect.none())
        }
        Error(err) -> {
          #(model.Model(..model, status: FetchError(err)), effect.none())
        }
      }
    }
  }
}
