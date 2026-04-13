/// Main application entry point

import frontend/effects
import frontend/model
import frontend/msg.{type Msg}
import frontend/toggle_handler_ffi
import frontend/update
import frontend/view
import lustre
import lustre/effect.{type Effect}

pub fn main() {
  // Initialize toggle handlers for vanilla JS event handling
  toggle_handler_ffi.init()

  let app = lustre.application(init, update.update, view.view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

/// Initialize the application with loading state and fetch todos effect
fn init(_flags: Nil) -> #(model.Model, Effect(Msg)) {
  #(model.default(), effects.fetch_todos())
}
