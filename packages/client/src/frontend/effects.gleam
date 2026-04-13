import frontend/msg.{type Msg}
import lustre/effect.{type Effect}

/// Create a todo via API - calls FFI JavaScript
pub fn create_todo(title: String, description: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // FFI call to JavaScript fetch
    do_create_todo(title, description, dispatch)
  })
}

/// Fetch all todos from API - calls FFI JavaScript
pub fn fetch_todos() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // FFI call to JavaScript fetch
    do_fetch_todos(dispatch)
  })
}

/// FFI function for creating a todo
@external(javascript, "./ffi.js", "createTodo")
fn do_create_todo(
  title: String,
  description: String,
  dispatch: fn(Msg) -> Nil,
) -> Nil

/// FFI function for fetching todos
@external(javascript, "./ffi.js", "fetchTodos")
fn do_fetch_todos(dispatch: fn(Msg) -> Nil) -> Nil
