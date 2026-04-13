import frontend/store_list/model as store_list_model
import frontend/store_list/msg as store_list_msg
import frontend/store_list/update as store_list_update
import frontend/store_list/view as store_list_view
import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element, map as element_map}

/// Page routes
pub type Route {
  StoreList
}

/// Application model that can hold different page states
pub type Model {
  Model(
    current_route: Route,
    store_list: store_list_model.Model,
  )
}

/// Application messages
pub type Msg {
  StoreListMsg(store_list_msg.Msg)
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_flags: Nil) -> #(Model, Effect(Msg)) {
  let store_list_model = store_list_model.default()

  // Trigger initial fetch
  let #(store_list_model, store_list_effect) = store_list_update.update(
    store_list_model,
    store_list_msg.DebouncedSearchTriggered,
  )

  let model = Model(
    current_route: StoreList,
    store_list: store_list_model,
  )

  let effect = effect.map(store_list_effect, StoreListMsg)

  #(model, effect)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    StoreListMsg(store_msg) -> {
      let #(updated_store_list, effect) = store_list_update.update(model.store_list, store_msg)
      #(Model(..model, store_list: updated_store_list), effect.map(effect, StoreListMsg))
    }
  }
}

fn view(model: Model) -> Element(Msg) {
  case model.current_route {
    StoreList -> {
      element_map(store_list_view.view(model.store_list), StoreListMsg)
    }
  }
}
