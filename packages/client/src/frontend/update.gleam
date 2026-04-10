import frontend/effects
import frontend/model.{type Model, Model}
import frontend/msg.{type Msg}
import gleam/option.{None}
import lustre/effect.{type Effect}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Counter demo messages (legacy)
    msg.Increment -> #(Model(..model, count: model.count + 1), effect.none())
    msg.Decrement -> #(Model(..model, count: model.count - 1), effect.none())
    msg.Reset -> #(Model(..model, count: 0), effect.none())

    // Auth messages: logout clears storage then redirects via StorageCleared
    msg.Logout -> #(Model(..model, user: None), effects.logout())
    msg.StorageCleared -> #(model, effect.none())
    msg.RedirectComplete -> #(model, effect.none())
  }
}
