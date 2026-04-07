import frontend/msg.{type Msg}
import lustre/effect.{type Effect}
import shared

@external(javascript, "./auth_ffi.mjs", "get_saved_token")
fn do_get_saved_token() -> String

@external(javascript, "./auth_ffi.mjs", "save_token")
fn do_save_token(token: String) -> Nil

@external(javascript, "./auth_ffi.mjs", "clear_token")
fn do_clear_token() -> Nil

@external(javascript, "./auth_ffi.mjs", "do_login")
fn ffi_login(
  email: String,
  password: String,
  on_ok: fn(String, String, String, String) -> Nil,
  on_err: fn(String) -> Nil,
) -> Nil

@external(javascript, "./auth_ffi.mjs", "do_register")
fn ffi_register(
  username: String,
  email: String,
  password: String,
  on_ok: fn(String, String, String, String) -> Nil,
  on_err: fn(String) -> Nil,
) -> Nil

@external(javascript, "./auth_ffi.mjs", "do_fetch_profile")
fn ffi_fetch_profile(
  token: String,
  on_ok: fn(String, String, String) -> Nil,
  on_err: fn(String) -> Nil,
) -> Nil

pub fn check_saved_token() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let token = do_get_saved_token()
    case token {
      "" -> Nil
      t -> dispatch(msg.GotSavedToken(t))
    }
  })
}

pub fn save_token(token: String) -> Effect(Msg) {
  effect.from(fn(_dispatch) { do_save_token(token) })
}

pub fn clear_token() -> Effect(Msg) {
  effect.from(fn(_dispatch) { do_clear_token() })
}

pub fn login(email: String, password: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    ffi_login(
      email,
      password,
      fn(token, id, username, user_email) {
        let user = shared.User(id: id, username: username, email: user_email)
        let resp = shared.AuthResponse(token: token, user: user)
        dispatch(msg.GotAuth(Ok(resp)))
      },
      fn(err) { dispatch(msg.GotAuth(Error(err))) },
    )
  })
}

pub fn register(
  username: String,
  email: String,
  password: String,
) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    ffi_register(
      username,
      email,
      password,
      fn(token, id, resp_username, user_email) {
        let user =
          shared.User(id: id, username: resp_username, email: user_email)
        let resp = shared.AuthResponse(token: token, user: user)
        dispatch(msg.GotAuth(Ok(resp)))
      },
      fn(err) { dispatch(msg.GotAuth(Error(err))) },
    )
  })
}

pub fn fetch_profile(token: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    ffi_fetch_profile(
      token,
      fn(id, username, email) {
        let user = shared.User(id: id, username: username, email: email)
        dispatch(msg.GotProfile(Ok(user)))
      },
      fn(err) { dispatch(msg.GotProfile(Error(err))) },
    )
  })
}
