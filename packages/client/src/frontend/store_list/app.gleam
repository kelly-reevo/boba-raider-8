/// Store List App - Main application module for the store list page
/// Follows Lustre MVU pattern: Model-View-Update

import frontend/store_list/model as store_model
import frontend/store_list/msg as store_msg
import frontend/store_list/update
import frontend/store_list/view
import lustre
import lustre/effect.{type Effect}

/// Initialize the store list application
pub fn main() {
  let app = lustre.application(init, update.update, view.view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

/// Initialize the model and trigger initial data load
fn init(_flags: Nil) -> #(store_model.Model, Effect(store_msg.Msg)) {
  let initial_model = store_model.default()

  // Trigger initial fetch with default params
  let url = "/api/stores?limit=20&offset=0&search=&sort_by=name&sort_order=asc"
  #(initial_model, fetch_initial_stores(url))
}

/// Initial fetch effect
fn fetch_initial_stores(url: String) -> Effect(store_msg.Msg) {
  effect.from(fn(dispatch) {
    fetch_stores_js(url, fn(result) {
      case result {
        Ok(#(stores, total)) -> dispatch(store_msg.StoresLoaded(stores, total))
        Error(err) -> dispatch(store_msg.StoresLoadFailed(err))
      }
    })
    Nil
  })
}

// FFI imports
@external(javascript, "./store_list_ffi.mjs", "fetchStores")
fn fetch_stores_js(
  url: String,
  callback: fn(Result(#(List(store_model.Store), Int), String)) -> Nil,
) -> Nil
