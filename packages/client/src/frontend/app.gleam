import frontend/model
import frontend/update
import frontend/view
import lustre

pub fn main() {
  let app = lustre.simple(init, update.update, view.view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_flags: Nil) -> model.Model {
  model.init()
}
