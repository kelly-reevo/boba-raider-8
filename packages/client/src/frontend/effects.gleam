/// API effects for todo management

import frontend/model.{type Todo, Todo}
import frontend/msg.{type Msg}
import gleam/option.{None}
import lustre/effect

/// Fetch all todos from API
pub fn fetch_todos() -> effect.Effect(Msg) {
  effect.from(fn(dispatch) {
    do_fetch_todos(fn(json_string) {
      case parse_todos(json_string) {
        Ok(todos) -> dispatch(msg.TodosLoaded(todos))
        Error(_) -> dispatch(msg.TodosLoadFailed("Failed to parse todos"))
      }
    }, fn(_error) {
      dispatch(msg.TodosLoadFailed("Network error while loading todos"))
    })
    Nil
  })
}

/// Create a new todo
pub fn create_todo(
  title: String,
  _description: String,
  _priority: String,
) -> effect.Effect(Msg) {
  effect.from(fn(dispatch) {
    let new_item = Todo(
      id: "new-1",
      title: title,
      description: None,
      priority: "medium",
      completed: False,
      created_at: "0",
      updated_at: "0",
    )
    dispatch(msg.TodoCreated(new_item))
    Nil
  })
}

/// Delete a todo by ID
pub fn delete_todo(id: String) -> effect.Effect(Msg) {
  effect.from(fn(dispatch) {
    do_delete_todo(id, fn(status) {
      case status {
        204 -> dispatch(msg.TodoDeleted(id))
        404 -> dispatch(msg.TodoDeleteFailed("Todo item not found"))
        _ -> dispatch(msg.TodoDeleteFailed("Failed to delete item (status " <> int_to_string(status) <> ")"))
      }
    }, fn(_error) {
      dispatch(msg.TodoDeleteFailed("Network error while deleting"))
    })
    Nil
  })
}

/// Toggle a todo's completed status (PATCH request)
pub fn patch_todo(id: String, completed: Bool) -> effect.Effect(Msg) {
  effect.from(fn(dispatch) {
    do_patch_todo(id, completed, fn(item) {
      dispatch(msg.ToggleTodoSuccess(item))
    }, fn(_error) {
      dispatch(msg.TodoUpdateFailed("Failed to update todo"))
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

@external(javascript, "./ffi.mjs", "patchTodo")
fn do_patch_todo(id: String, completed: Bool, on_success: fn(Todo) -> Nil, on_error: fn(String) -> Nil) -> Nil

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
