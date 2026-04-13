/// Main application entry point for the Lustre frontend

import frontend/effects
import frontend/model
import frontend/msg.{type Msg}
import frontend/update
import frontend/view
import lustre
import lustre/effect.{type Effect}

/// Start the application
pub fn main() {
  let app = lustre.application(init, update.update, view.view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

/// Initialize the application state and trigger initial data load
fn init(_flags: Nil) -> #(model.Model, Effect(Msg)) {
  #(model.default(), effects.fetch_todos())
}
