import frontend/effects
import frontend/model.{type Model}
import frontend/msg.{type Msg}
import frontend/update
import frontend/view
import gleam/option.{None, Some}
import lustre
import lustre/effect.{type Effect}

pub fn main() {
  let app = lustre.application(init, update.update, view.view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_flags: Nil) -> #(Model, Effect(Msg)) {
  // Check if we're on a store detail route
  let store_id = extract_store_id_from_route()

  case store_id {
    Some(id) -> {
      // Initialize store detail view with loading state and fetch data
      #(model.init_store_detail(id), effects.fetch_store_data(id))
    }
    None -> {
      // Default initialization
      #(model.default(), effect.none())
    }
  }
}

/// Extract store ID from current route path
/// Matches /stores/:id pattern
fn extract_store_id_from_route() -> option.Option(String) {
  // In a real app, this would parse window.location.pathname
  // For now, we return None to default to loading state
  // This can be enhanced with proper routing integration
  None
}
