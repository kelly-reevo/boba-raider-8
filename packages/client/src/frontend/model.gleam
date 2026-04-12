/// Application state for todo list display

import gleam/option.{type Option, None, Some}
import shared.{type Todo}

/// Loading state for async operations
pub type LoadingState {
  Idle
  Loading
  Success
  Error(String)
}

/// Model for the todo list application
pub type Model {
  Model(
    todos: List(Todo),
    loading: LoadingState,
    error: String,
  )
}

/// Default initial state
pub fn default() -> Model {
  Model(
    todos: [],
    loading: Idle,
    error: "",
  )
}

/// Check if model has any todos
pub fn has_todos(model: Model) -> Bool {
  case model.todos {
    [] -> False
    _ -> True
  }
}

/// Find a todo by id
pub fn find_todo(model: Model, id: String) -> Option(Todo) {
  case list.find(model.todos, fn(t) { t.id == id }) {
    Ok(t) -> Some(t)
    _ -> None
  }
}

// Import required at bottom to avoid circular issues with find_todo
import gleam/list
