/// Application messages

import shared

pub type Msg {
  // Navigation
  GoToLogin
  GoToRegister
  GoToProfile
  // Form inputs
  SetEmail(String)
  SetPassword(String)
  SetUsername(String)
  // Auth actions
  SubmitLogin
  SubmitRegister
  Logout
  // API responses
  GotAuth(Result(shared.AuthResponse, String))
  GotProfile(Result(shared.User, String))
  // Init: restore session from localStorage
  GotSavedToken(String)
}
