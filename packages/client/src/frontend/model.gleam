/// Application state for todo list application

import gleam/option.{type Option, None, Some}
import gleam/list
import shared.{type Todo}

/// Loading state for async operations
pub type LoadingState {
  Idle
  Loading
  Success
  Error(String)
}

/// Error types for error display
pub type ErrorType {
  Network
  Server
  Validation
}

/// Error record for structured error handling
pub type ErrorInfo {
  ErrorInfo(id: String, message: String, type_: ErrorType)
}

/// Model for the todo list application
pub type Model {
  Model(
    todos: List(Todo),
    loading: LoadingState,
    error: String,
    deleting_id: Option(String),
    errors: List(ErrorInfo),
  )
}

/// Default initial state
pub fn default() -> Model {
  Model(
    todos: [],
    loading: Idle,
    error: "",
    deleting_id: None,
    errors: [],
  )
}

/// Check if model has any todos
pub fn has_todos(model: Model) -> Bool {
  case model.todos {
    [] -> False
    _ -> True
  }
}

/// Check if model has no todos (for empty state display)
pub fn is_empty(model: Model) -> Bool {
  case model.todos {
    [] -> True
    _ -> False
  }
}

/// Remove a todo by ID from the model
pub fn remove_todo(model: Model, id: String) -> Model {
  Model(
    ..model,
    todos: remove_by_id(model.todos, id),
    deleting_id: None,
  )
}

/// Helper to filter out a todo by ID
fn remove_by_id(todos: List(Todo), id: String) -> List(Todo) {
  case todos {
    [] -> []
    [first, ..rest] -> {
      case first.id == id {
        True -> rest
        False -> [first, ..remove_by_id(rest, id)]
      }
    }
  }
}

/// Find a todo by id
pub fn find_todo(model: Model, id: String) -> Option(Todo) {
  case list.find(model.todos, fn(t) { t.id == id }) {
    Ok(t) -> Some(t)
    _ -> None
  }
}

/// Remove an error by ID from the model
pub fn dismiss_error(model: Model, error_id: String) -> Model {
  Model(
    ..model,
    errors: list.filter(model.errors, fn(e) { e.id != error_id }),
  )
}
