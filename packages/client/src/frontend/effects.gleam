/// HTTP effects for todo operations

import frontend/msg.{type Msg, TodosLoaded}
import frontend/todo_types.{type Filter, type Todo, All, Active, Completed}
import lustre/effect.{type Effect}

/// Fetch todos with optional status filter
pub fn list_todos(filter: Filter) -> Effect(Msg) {
  let filter_str = case filter {
    All -> "all"
    Active -> "active"
    Completed -> "completed"
  }

  let url = "/api/todos?status=" <> filter_str

  effect.from(fn(dispatch) {
    do_fetch(url, fn(result) {
      dispatch(TodosLoaded(result))
    })
  })
}

@external(javascript, "../client_ffi.mjs", "fetchTodos")
fn do_fetch(url: String, callback: fn(Result(List(Todo), String)) -> Nil) -> Nil
