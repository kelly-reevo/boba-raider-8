import frontend/effects
import frontend/model.{type Model, Model}
import frontend/msg.{type Msg}
import lustre/effect.{type Effect}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    msg.Increment -> #(model, effects.post_increment())
    msg.Decrement -> #(model, effects.post_decrement())
    msg.Reset -> #(model, effects.post_reset())
    msg.GotCounter(Ok(count)) -> #(Model(count: count, error: ""), effect.none())
    msg.GotCounter(Error(_)) -> #(Model(..model, error: "Failed to reach server"), effect.none())
  }
}
