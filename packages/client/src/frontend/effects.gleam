import frontend/msg.{type Msg}
import lustre/effect.{type Effect}

/// Fetch todos from GET /api/todos
pub fn fetch_todos() -> Effect(Msg) {
  use dispatch <- effect.from

  // For JavaScript target, use browser fetch via FFI
  do_fetch_todos(dispatch, "/api/todos")
  Nil
}

@external(javascript, "./effects_ffi.mjs", "fetchTodos")
fn do_fetch_todos(dispatch: fn(Msg) -> Nil, url: String) -> Nil
