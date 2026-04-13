/// Re-export API effects from api.gleam

import frontend/api
import frontend/msg.{type Msg}
import lustre/effect.{type Effect}

/// Re-export patch_todo from api module
pub fn patch_todo(id: String, completed: Bool) -> Effect(Msg) {
  api.patch_todo(id, completed)
}

/// Fetch all todos
pub fn fetch_todos() -> Effect(Msg) {
  api.fetch_todos()
}
