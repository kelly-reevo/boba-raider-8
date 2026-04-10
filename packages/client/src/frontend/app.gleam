import frontend/effects
import frontend/model.{type Model}
import frontend/msg.{type Msg, InitApp}
import frontend/update
import frontend/view
import lustre
import lustre/effect.{type Effect}

pub fn main() {
  let app = lustre.application(init, update.update, view.view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_flags: Nil) -> #(Model, Effect(Msg)) {
  let model = model.default()
  // Load token from localStorage on app startup
  #(model, effects.load_token_from_storage())
}
