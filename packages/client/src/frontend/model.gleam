/// Application state

import gleam/option.{type Option}
import shared.{type Todo}

/// Loading state for async operations
pub type LoadingState {
  Idle
  Loading
  Error(String)
}

/// Model containing todos and UI state
pub type Model {
  Model(
    todos: List(Todo),
    loading_state: LoadingState,
    deleting_id: Option(String),
  )
}

/// Default empty model
pub fn default() -> Model {
  Model(todos: [], loading_state: Idle, deleting_id: option.None)
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
    deleting_id: option.None,
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
