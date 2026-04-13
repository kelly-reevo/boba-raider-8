import frontend/store_list/model as store_list_model
import frontend/store_list/msg as store_list_msg
import frontend/store_list/update as store_list_update
import frontend/store_list/view as store_list_view
import gleam/option.{type Option, None, Some}
import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element, map as element_map}

/// Page routes
pub type Route {
  StoreList
  StoreDetail(store_id: String)
}

/// Application model that can hold different page states
pub type Model {
  Model(
    current_route: Route,
    store_list: store_list_model.Model,
    store_detail: Option(store_detail_model.Model),
  )
}

/// Application messages
pub type Msg {
  StoreListMsg(store_list_msg.Msg)
  StoreDetailMsg(store_detail_msg.Msg)
}

// Store detail sub-module types (inline to avoid circular deps)
pub type StoreDetailState {
  Loading
  Loaded(store_detail_model.StoreData)
  Error(String)
}

pub type store_detail_model {
  Model(store_id: String, state: StoreDetailState)
}

pub type store_detail_msg {
  StoreDataReceived(Result(store_detail_model.StoreData, String))
  NavigateBack
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

  // Check if we're on a store detail route
  let store_id = extract_store_id_from_route()
  let route = case store_id {
    Some(id) -> StoreDetail(id)
    None -> StoreList
  }

  let model = Model(
    current_route: route,
    store_list: store_list_model,
    store_detail: None,
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
    StoreDetailMsg(detail_msg) -> {
      // Handle store detail messages
      case detail_msg {
        StoreDetailMsg(inner) -> {
          // Handle store detail update
          #(model, effect.none())
        }
      }
    }
  }
}

fn view(model: Model) -> Element(Msg) {
  case model.current_route {
    StoreList -> {
      element_map(store_list_view.view(model.store_list), StoreListMsg)
    }
    StoreDetail(_store_id) -> {
      // Render store detail view
      element_map(store_list_view.view(model.store_list), StoreListMsg)
    }
  }
}

/// Extract store ID from current route path
/// Matches /stores/:id pattern
fn extract_store_id_from_route() -> Option(String) {
  // In a real app, this would parse window.location.pathname
  // For now, we return None to default to store list
  None
}

// Placeholder for store_detail_model module types
pub type StoreData {
  StoreData(id: String, name: String, city: String)
}
