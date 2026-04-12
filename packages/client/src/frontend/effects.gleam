/// Effects for API operations and side effects

import frontend/msg.{type Msg}
import lustre/effect.{type Effect}

/// Fetch all todos from the API
/// Placeholder - actual HTTP implementation would use lustre_http
pub fn fetch_todos() -> Effect(Msg) {
  effect.none()
}

/// Effect to send after todos are loaded
pub fn todos_loaded(result: Result(List(a), String)) -> Effect(Msg) {
  effect.none()
}
