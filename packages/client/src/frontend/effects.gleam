/// Effects for localStorage and API calls

/// Clear local storage and redirect (used on logout)
/// Executes: localStorage.clear() then window.location.href = "/"
pub fn logout() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    do_logout()
    dispatch(msg.StorageCleared)
  })
}

/// Perform the actual logout via FFI
@external(javascript, "../ffi.mjs", "logout")
fn do_logout() -> Nil {
  Nil
}

/// Save auth token to localStorage on login
pub fn save_token_to_storage(user: User, token: AuthToken) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let _ = do_save_to_storage(user, token)
    dispatch(TokenCleared)
  })
}

/// Clear auth token from localStorage on logout
pub fn clear_token() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    do_clear_storage()
    dispatch(TokenCleared)
  })
}

// ---------------------------------------------------------------------------
// localStorage FFI
// ---------------------------------------------------------------------------

/// Load auth data from localStorage - returns tuple of user and token
@external(javascript, "./client_ffi.mjs", "loadAuthFromStorage")
fn do_load_from_storage() -> Result(#(User, AuthToken), String)

/// Save auth data to localStorage
@external(javascript, "./client_ffi.mjs", "saveAuthToStorage")
fn do_save_to_storage(user: User, token: AuthToken) -> Bool

/// Clear auth data from localStorage
@external(javascript, "./client_ffi.mjs", "clearAuthFromStorage")
fn do_clear_storage() -> Nil

// ---------------------------------------------------------------------------
// API Effects
// ---------------------------------------------------------------------------

/// Submit login credentials to API
pub fn submit_login(email: String, password: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // Simulate API call - replace with actual HTTP request
    case do_login_api_call(email, password) {
      Ok(response) -> dispatch(LoginSuccess(response))
      Error(err) -> dispatch(LoginFailure(err))
    }
  })
}

/// Submit registration data to API
pub fn submit_register(
  username: String,
  email: String,
  password: String,
) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // Simulate API call - replace with actual HTTP request
    case do_register_api_call(username, email, password) {
      Ok(response) -> dispatch(RegisterSuccess(response))
      Error(err) -> dispatch(RegisterFailure(err))
    }
  })
}

// ---------------------------------------------------------------------------
// API FFI
// ---------------------------------------------------------------------------

/// Perform login API call
@external(javascript, "./client_ffi.mjs", "loginApiCall")
fn do_login_api_call(email: String, password: String) -> Result(AuthResponse, shared.AppError)

/// Perform registration API call
@external(javascript, "./client_ffi.mjs", "registerApiCall")
fn do_register_api_call(username: String, email: String, password: String) -> Result(AuthResponse, shared.AppError)
