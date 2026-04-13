/// HTTP effects for fetching todos

import frontend/msg.{type Msg, TodosLoaded, TodosLoadError}
import lustre/effect.{type Effect}
import shared.{type Todo}

/// Fetch todos from the API
pub fn fetch_todos() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    do_fetch_todos(dispatch)
  })
}

/// Perform the actual HTTP fetch
fn do_fetch_todos(dispatch: fn(Msg) -> Nil) -> Nil {
  let url = "/api/todos"

  fetch_send(url, fn(todos_result) {
    case todos_result {
      Ok(todos) -> dispatch(TodosLoaded(todos))
      Error(err) -> dispatch(TodosLoadError(err))
    }
  })

  Nil
}

/// FFI: Send fetch request
/// Takes a URL string and a callback that receives either Ok(todos) or Error(error_message)
@external(javascript, "../ffi/fetch_ffi.mjs", "fetchTodos")
fn fetch_send(url: String, callback: fn(Result(List(Todo), String)) -> Nil) -> Nil
