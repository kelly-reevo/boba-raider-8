/// Application effects for HTTP and navigation

import frontend/model.{type AuthState, AuthAuthenticated, AuthUnauthenticated}
import frontend/msg.{
  type Msg, AuthStatusReturned, LoginFailed, LoginSucceeded, LogoutCompleted,
}
import lustre/effect.{type Effect}

/// Navigate to a route (browser location change)
pub fn navigate_to(path: String) -> Effect(Msg) {
  effect.from(fn(_dispatch) {
    do_navigate_to(path)
    Nil
  })
}

@external(javascript, "../ffi.mjs", "navigateTo")
fn do_navigate_to(path: String) -> Nil

/// Check authentication status on init
pub fn check_auth_status() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    do_check_auth_status(fn(auth_json) {
      let auth_state = parse_auth_response(auth_json)
      dispatch(AuthStatusReturned(auth_state))
    })
    Nil
  })
}

@external(javascript, "../ffi.mjs", "checkAuthStatus")
fn do_check_auth_status(callback: fn(String) -> Nil) -> Nil

/// Login request
pub fn login(username: String, password: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    do_login(username, password, fn(result_json) {
      let result = parse_login_response(result_json)
      case result {
        Ok(#(user_id, username_val)) -> dispatch(LoginSucceeded(user_id, username_val))
        Error(msg) -> dispatch(LoginFailed(msg))
      }
    })
    Nil
  })
}

@external(javascript, "../ffi.mjs", "login")
fn do_login(
  username: String,
  password: String,
  callback: fn(String) -> Nil,
) -> Nil

/// Logout request
pub fn logout() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    do_logout(fn(_) {
      dispatch(LogoutCompleted)
    })
    Nil
  })
}

@external(javascript, "../ffi.mjs", "logout")
fn do_logout(callback: fn(String) -> Nil) -> Nil

/// Parse auth status JSON response
/// Returns authenticated state from JSON: { "authenticated": bool, "user": { "id": string, "username": string } }
fn parse_auth_response(json_str: String) -> Result(AuthState, String) {
  // Use FFI to parse JSON
  case do_parse_auth_json(json_str) {
    #(True, user_id, username) -> Ok(AuthAuthenticated(user_id, username))
    #(False, _, _) -> Ok(AuthUnauthenticated)
  }
}

@external(javascript, "../ffi.mjs", "parseAuthJson")
fn do_parse_auth_json(json_str: String) -> #(Bool, String, String)

/// Parse login JSON response
/// Returns user info from JSON: { "user_id": string, "username": string }
fn parse_login_response(json_str: String) -> Result(#(String, String), String) {
  case do_parse_login_json(json_str) {
    #(True, user_id, username) -> Ok(#(user_id, username))
    #(False, _, _) -> Error("Login failed")
  }
}

@external(javascript, "../ffi.mjs", "parseLoginJson")
fn do_parse_login_json(json_str: String) -> #(Bool, String, String)
