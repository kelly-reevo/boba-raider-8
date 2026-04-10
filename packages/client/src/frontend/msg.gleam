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
  // Counter demo messages (legacy)
  Increment
  Decrement
  Reset

  // Auth messages
  Logout
  StorageCleared
  RedirectComplete
}
