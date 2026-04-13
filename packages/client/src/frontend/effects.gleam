/// Re-export API effects from api.gleam and delete effects

import frontend/api
import frontend/msg.{type Msg}
import lustre/effect.{type Effect}
import shared.{type Todo}

/// Re-export patch_todo from api module
pub fn patch_todo(id: String, completed: Bool) -> Effect(Msg) {
  api.patch_todo(id, completed)
}

/// Fetch all todos
pub fn fetch_todos() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    do_fetch_todos(fn(json_string) {
      case parse_todos(json_string) {
        Ok(todos) -> dispatch(msg.TodosLoaded(todos))
        Error(_) -> dispatch(msg.TodosLoadError("Error: Failed to parse todos"))
      }
    }, fn(_error) {
      dispatch(msg.TodosLoadError("Error: Network failure while loading todos"))
    })
    Nil
  })
}

/// Delete a todo by ID using JavaScript fetch
pub fn delete_todo(id: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    do_delete_todo(id, fn(status) {
      case status {
        204 -> dispatch(msg.DeleteTodoSuccess(id))
        404 -> dispatch(msg.DeleteTodoError("Error: Todo item not found"))
        _ -> dispatch(msg.DeleteTodoError("Error: Failed to delete item (status " <> int_to_string(status) <> ")"))
      }
    }, fn(_error) {
      dispatch(msg.DeleteTodoError("Error: Network failure while deleting item"))
    })
    Nil
  })
}

/// Parse a list of todos from JSON string
fn parse_todos(json_string: String) -> Result(List(Todo), Nil) {
  case do_parse_todos(json_string) {
    Ok(todos) -> Ok(todos)
    Error(_) -> Error(Nil)
  }
}

// FFI functions
@external(javascript, "./ffi.mjs", "deleteTodo")
fn do_delete_todo(id: String, on_success: fn(Int) -> Nil, on_error: fn(String) -> Nil) -> Nil

@external(javascript, "./ffi.mjs", "fetchTodos")
fn do_fetch_todos(on_success: fn(String) -> Nil, on_error: fn(String) -> Nil) -> Nil

@external(javascript, "./ffi.mjs", "parseTodos")
fn do_parse_todos(json_string: String) -> Result(List(Todo), Nil)

fn int_to_string(n: Int) -> String {
  case n {
    0 -> "0"
    n if n < 0 -> "-" <> int_to_string(-n)
    n -> int_to_string_positive(n, "")
  }
}

fn int_to_string_positive(n: Int, acc: String) -> String {
  case n {
    0 -> acc
    _ -> int_to_string_positive(n / 10, case n % 10 {
      0 -> "0" <> acc
      1 -> "1" <> acc
      2 -> "2" <> acc
      3 -> "3" <> acc
      4 -> "4" <> acc
      5 -> "5" <> acc
      6 -> "6" <> acc
      7 -> "7" <> acc
      8 -> "8" <> acc
      9 -> "9" <> acc
      _ -> acc
    })
  }
}
