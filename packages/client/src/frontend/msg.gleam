/// Application messages for routing, auth, and form handling

import shared.{type User, type AuthToken, type AuthResponse, type AppError}

/// Routes in the application
pub type Route {
  Home
  Login
  Register
}

/// Navigation messages
pub type Msg {
  /// Navigate to a different route
  NavigateTo(route: Route)

  /// Initialize app (load from localStorage)
  InitApp

  // Login form messages
  LoginEmailChanged(String)
  LoginPasswordChanged(String)
  LoginSubmitted
  LoginSuccess(AuthResponse)
  LoginFailure(AppError)

  // Register form messages
  RegisterUsernameChanged(String)
  RegisterEmailChanged(String)
  RegisterPasswordChanged(String)
  RegisterConfirmPasswordChanged(String)
  RegisterSubmitted
  RegisterSuccess(AuthResponse)
  RegisterFailure(AppError)

  // Auth lifecycle messages
  LogoutRequested
  LogoutCompleted

  // localStorage messages
  TokenLoadedFromStorage(User, AuthToken)
  TokenStorageError(String)
  TokenCleared

  // Counter messages (legacy, kept for compatibility)
  Increment
  Decrement
  Reset
}
