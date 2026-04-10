import frontend/msg.{type Msg}
import lustre/effect.{type Effect}

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
