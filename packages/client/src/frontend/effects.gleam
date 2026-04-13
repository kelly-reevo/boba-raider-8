/// Effects for API operations with loading state integration

import frontend/msg.{type Msg}
import lustre/effect.{type Effect}

/// Fetch todos - triggers loading state
pub fn fetch_todos() -> Effect(Msg) {
  effect.none()
}

/// Add todo effect
pub fn add_todo(_title: String, _description: String) -> Effect(Msg) {
  effect.none()
}

/// Toggle todo effect
pub fn toggle_todo(_id: String, _completed: Bool) -> Effect(Msg) {
  effect.none()
}

/// Delete todo effect
pub fn delete_todo(_id: String) -> Effect(Msg) {
  effect.none()
}
