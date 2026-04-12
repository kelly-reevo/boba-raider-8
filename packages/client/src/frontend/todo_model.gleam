/// Todo list state management

import gleam/option.{type Option}
import shared.{type Todo}

/// Loading state for async operations
pub type LoadingState {
  Idle
  Loading
  Error(String)
  Success
}

/// Todo list model extending the base model
pub type TodoModel {
  TodoModel(
    todos: List(Todo),
    loading_state: LoadingState,
  )
}

/// Default/initial todo model
pub fn todo_model_default() -> TodoModel {
  TodoModel(
    todos: [],
    loading_state: Idle,
  )
}
