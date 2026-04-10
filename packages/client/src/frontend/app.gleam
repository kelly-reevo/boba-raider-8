import frontend/model
import frontend/msg.{type Msg, StoreList, LoadStores}
import frontend/update
import frontend/view
import frontend/effects
import lustre
import lustre/effect.{type Effect}
import shared

pub fn main() {
  let app = lustre.application(init, update.update, view.view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_flags: Nil) -> #(model.Model, Effect(Msg)) {
  #(model.with_store_list_loading(), effects.fetch_stores(shared.default_filters()))
}
