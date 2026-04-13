/// Main application entry point

import frontend/effects
import frontend/model
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

fn init(_flags: Nil) -> #(model.Model, Effect(Msg)) {
  let initial_model = model.init()

  // Trigger initial data fetch with loading state
  #(initial_model, effects.fetch_todos())
}
