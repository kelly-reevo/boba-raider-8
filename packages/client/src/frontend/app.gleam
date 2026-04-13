import frontend/effects
import frontend/model.{type Model, All}
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

fn init(_flags: Nil) -> #(Model, Effect(Msg)) {
  let initial_model = model.default()
  // Load todos with default filter (All) on init
  #(initial_model, effects.fetch_todos(All))
}
