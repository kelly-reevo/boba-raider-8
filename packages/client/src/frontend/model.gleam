import gleam/option.{type Option}
import shared.{type Drink, type Rating}

import frontend/rating_model.{type RatingForm}
import gleam/option.{type Option, None}

import frontend/components/store_rating_form.{type StoreRatingFormModel}
import gleam/option.{type Option, None}

import frontend/route.{type Route}

/// User authentication state
pub type AuthState {
  /// Authentication status unknown (loading)
  AuthLoading
  /// User not authenticated
  AuthUnauthenticated
  /// User authenticated with details
  AuthAuthenticated(user_id: String, username: String)
}

/// Page state for loading/error/empty/populated pattern
pub type PageData(data) {
  PageLoading
  PageEmpty
  PageError(message: String)
  PagePopulated(data: data)
}

/// Application model containing all state
pub type Model {
  Model(
    /// Current active route
    current_route: Route,
    /// Current authentication state
    auth_state: AuthState,
    /// Redirect path after login (if redirected from protected route)
    post_login_redirect: Option(String),
  )
}

/// Optional type helper
pub type Option(a) {
  None
  Some(a)
}

/// Create default model
pub fn default() -> Model {
  Model(
    current_route: route.from_path("/"),
    auth_state: AuthLoading,
    post_login_redirect: None,
  )
}

/// Check if user is authenticated
pub fn is_authenticated(model: Model) -> Bool {
  case model.auth_state {
    AuthAuthenticated(_, _) -> True
    _ -> False
  }
}

/// Get username if authenticated
pub fn get_username(model: Model) -> String {
  case model.auth_state {
    AuthAuthenticated(_, username) -> username
    _ -> ""
  }
}

/// Check if route can be accessed with current auth state
pub fn can_access_route(model: Model, route: Route) -> Bool {
  case route.is_protected(route) {
    False -> True
    True -> is_authenticated(model)
  }
}

/// Get redirect path for login with current route preserved
pub fn get_login_redirect_path(model: Model) -> String {
  case model.post_login_redirect {
    Some(path) -> path
    None -> route.login_redirect_path()
  }
}
