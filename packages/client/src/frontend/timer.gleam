/// Timer utilities for transient errors

import frontend/msg.{type Msg}
import lustre/effect.{type Effect}

/// Start a timer that dispatches a message after delay (in milliseconds)
@external(javascript, "./timer_ffi.mjs", "setTimeoutEffect")
pub fn set_timeout_effect(
  dispatch: fn(Msg) -> Nil,
  msg: Msg,
  delay: Int,
) -> Nil

/// Effect to clear transient error after 5 seconds
pub fn clear_after_delay(msg: Msg) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    set_timeout_effect(dispatch, msg, 5000)
    Nil
  })
}
