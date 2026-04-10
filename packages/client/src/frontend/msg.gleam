/// Application messages

import frontend/model.{type AuthState}
import frontend/route.{type Route}

/// All possible messages in the application
pub type Msg {
  /// Route changed (from URL)
  RouteChanged(route: Route)
  /// Navigate to a route programmatically
  NavigateTo(route: Route)
  /// Authentication state changed
  AuthStateChanged(auth_state: AuthState)
  /// Login requested
  LoginRequested(username: String, password: String)
  /// Login succeeded
  LoginSucceeded(user_id: String, username: String)
  /// Login failed
  LoginFailed(error: String)
  /// Logout requested
  LogoutRequested
  /// Logout completed
  LogoutCompleted
  /// Check auth status on init
  CheckAuthStatus
  /// Auth status check returned
  AuthStatusReturned(result: Result(AuthState, String))
  /// Store redirect path for after login
  SetPostLoginRedirect(path: String)
  /// Clear redirect path
  ClearPostLoginRedirect
}
