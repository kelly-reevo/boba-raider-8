import frontend/model.{type Model, HomePage, StoreDetailPage}
import frontend/msg.{type Msg}
import frontend/update
import frontend/view
import gleam/string
import gleam/uri.{type Uri}
import lustre
import lustre/effect.{type Effect}
import modem

pub fn main() {
  let app = lustre.application(init, update.update, view.view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_flags: Nil) -> #(Model, Effect(Msg)) {
  #(model.default(), modem.init(on_url_change))
}

fn on_url_change(uri: Uri) -> Msg {
  let page = case string.split(uri.path, "/") {
    ["", "stores", id] -> StoreDetailPage(id)
    _ -> HomePage
  }
  msg.OnRouteChange(page)
}
