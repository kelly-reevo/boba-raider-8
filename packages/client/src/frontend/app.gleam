/// Main application entry point
/// Initializes the Lustre application with todo list functionality
/// Fetches initial data on page load

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

/// Initialize the application with loading state and trigger todo fetch
fn init(_flags: Nil) -> #(model.Model, Effect(Msg)) {
  #(model.default(), effects.fetch_todos())
}
