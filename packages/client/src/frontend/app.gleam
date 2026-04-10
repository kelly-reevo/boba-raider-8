/// Main application entry point with routing setup

import frontend/effects
import frontend/model.{type Model, Model, default}
import frontend/msg.{type Msg}
import frontend/route.{type Route, from_path}
import frontend/update
import frontend/view
import frontend/effects
import lustre
import lustre/effect.{type Effect}
import shared

/// Main application entry point
pub fn main() {
  let app = lustre.application(init, update.update, view.view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  // Listen for browser navigation (back/forward buttons)
  setup_popstate_listener(fn(path) {
    let route = from_path(path)
    // Dispatch route change message to the running app
    dispatch_route_change(route)
  })

  Nil
}

/// Initialize the application
fn init(_flags: Nil) -> #(Model, Effect(Msg)) {
  let initial_route = get_current_path() |> from_path()
  let model = Model(
    ..default(),
    current_route: initial_route,
  )

  // Check auth status on init
  #(model, effects.check_auth_status())
}

/// Get current browser path
@external(javascript, "../ffi.mjs", "getCurrentPath")
fn get_current_path() -> String

/// Setup browser popstate listener for back/forward buttons
@external(javascript, "../ffi.mjs", "setupPopstateListener")
fn setup_popstate_listener(callback: fn(String) -> Nil) -> Nil

/// Dispatch route change to the application
@external(javascript, "../ffi.mjs", "dispatchRouteChange")
fn dispatch_route_change(route: Route) -> Nil
