import frontend/msg
import lustre/effect.{type Effect}

/// Fetch todos from the API using JavaScript FFI
pub fn fetch_todos() -> Effect(msg.Msg) {
  use dispatch <- effect.from()
  do_fetch_todos(dispatch)
}

/// FFI to fetch todos from the API (JavaScript only)
/// The JavaScript will call the dispatch function with the result
@external(javascript, "./ffi.js", "fetchTodos")
fn do_fetch_todos(_dispatch: fn(msg.Msg) -> Nil) -> Nil {
  Nil
}
