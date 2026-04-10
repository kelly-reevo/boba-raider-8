/// State updates and route guards

import frontend/effects
import frontend/model.{
  type Model, Model, AuthAuthenticated, AuthUnauthenticated, None, Some,
  can_access_route, is_authenticated,
}
import frontend/msg.{type Msg}
import frontend/route.{type Route, Login, login_redirect_path, to_path, is_protected}
import lustre/effect.{type Effect}

/// Main update function
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Route changes with authentication guard
    msg.RouteChanged(route) -> handle_route_change(model, route)

    // Programmatic navigation with auth check
    msg.NavigateTo(route) -> handle_navigate_to(model, route)

    // Authentication state updates
    msg.AuthStateChanged(auth_state) -> {
      let new_model = Model(..model, auth_state: auth_state)
      #(new_model, effect.none())
    }

    // Login flow
    msg.LoginRequested(username, password) -> {
      #(model, effects.login(username, password))
    }

    msg.LoginSucceeded(user_id, username) -> {
      let auth_state = AuthAuthenticated(user_id, username)
      let redirect = model.post_login_redirect
      let new_model = Model(
        ..model,
        auth_state: auth_state,
        post_login_redirect: None,
      )
      // Redirect to saved path or home after login
      let effect = case redirect {
        Some(path) -> effects.navigate_to(path)
        None -> effects.navigate_to("/")
      }
      #(new_model, effect)
    }

    msg.LoginFailed(_error) -> {
      // Keep model unchanged, error displayed via auth state
      #(model, effect.none())
    }

    // Logout flow
    msg.LogoutRequested -> {
      #(model, effects.logout())
    }

    msg.LogoutCompleted -> {
      let new_model = Model(..model, auth_state: AuthUnauthenticated)
      // Redirect to home after logout
      #(new_model, effects.navigate_to("/"))
    }

    // Auth status check on init
    msg.CheckAuthStatus -> {
      #(model, effects.check_auth_status())
    }

    msg.AuthStatusReturned(result) -> {
      let auth_state = case result {
        Ok(state) -> state
        Error(_) -> AuthUnauthenticated
      }
      #(Model(..model, auth_state: auth_state), effect.none())
    }

    // Redirect path management
    msg.SetPostLoginRedirect(path) -> {
      #(Model(..model, post_login_redirect: Some(path)), effect.none())
    }

    msg.ClearPostLoginRedirect -> {
      #(Model(..model, post_login_redirect: None), effect.none())
    }
  }
}

/// Handle route changes with authentication guard
fn handle_route_change(model: Model, route_val: Route) -> #(Model, Effect(Msg)) {
  // Check if route requires auth and user is not authenticated
  case is_protected(route_val) && !is_authenticated(model) {
    True -> {
      // Save current path and redirect to login
      let current_path = to_path(route_val)
      let new_model = Model(
        ..model,
        current_route: Login,
        post_login_redirect: Some(current_path),
      )
      #(new_model, effects.navigate_to(login_redirect_path()))
    }
    False -> {
      // Allow access
      #(Model(..model, current_route: route_val), effect.none())
    }
  }
}

/// Handle programmatic navigation with auth check
fn handle_navigate_to(model: Model, route_val: Route) -> #(Model, Effect(Msg)) {
  case can_access_route(model, route_val) {
    True -> {
      let path = to_path(route_val)
      #(Model(..model, current_route: route_val), effects.navigate_to(path))
    }
    False -> {
      // Save intended destination and redirect to login
      let path = to_path(route_val)
      let new_model = Model(
        ..model,
        post_login_redirect: Some(path),
      )
      #(new_model, effects.navigate_to(login_redirect_path()))
    }
  }
}
