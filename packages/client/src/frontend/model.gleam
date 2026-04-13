/// Application state

import gleam/option.{type Option}
import gleam/list

/// Todo item data model
pub type Todo {
  Todo(
    id: String,
    title: String,
    priority: String,
    completed: Bool,
  )
}

/// Loading state for async operations
pub type LoadingState {
  Idle
  Loading
  Error(String)
}

/// Application model
pub type Model {
  Model(
    todos: List(Todo),
    loading_state: LoadingState,
    deleting_id: Option(String),
  )
}

/// Default/initial model state
pub fn default() -> Model {
  Model(
    todos: [],
    loading_state: Idle,
    deleting_id: option.None,
  )
}

/// Remove a todo by ID from the list
pub fn remove_todo(model: Model, id: String) -> Model {
  Model(
    ..model,
    todos: list.filter(model.todos, fn(item) { item.id != id }),
    deleting_id: option.None,
  )
}

/// Set the ID currently being deleted
pub fn set_deleting(model: Model, id: String) -> Model {
  Model(..model, deleting_id: option.Some(id))
}

/// Clear any error state
pub fn clear_error(model: Model) -> Model {
  Model(..model, loading_state: Idle)
}

/// Set error state with message
pub fn set_error(model: Model, message: String) -> Model {
  Model(..model, loading_state: Error(message), deleting_id: option.None)
}
