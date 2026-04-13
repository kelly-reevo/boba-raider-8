import frontend/model.{type Model}
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

fn init(_flags: Nil) -> #(Model, Effect(Msg)) {
  #(model.default(), effect.none())
}
