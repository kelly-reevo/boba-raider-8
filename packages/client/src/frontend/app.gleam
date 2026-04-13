/// Application entry point with initial load

import frontend/effects
import frontend/model as model
import frontend/msg.{type Msg}
import frontend/update
import frontend/view
import lustre
import lustre/effect.{type Effect}

pub fn main() {
  let app = lustre.application(init, update.update, view.view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_flags: Nil) -> #(model.AppModel, Effect(Msg)) {
  // Initialize with loading state and trigger fetch
  #(model.default(), effects.load_todos())
}
