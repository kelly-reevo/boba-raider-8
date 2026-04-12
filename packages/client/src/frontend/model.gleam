/// Application state

import gleam/option.{type Option}
import shared.{type Todo}

/// Loading state for async operations
pub type LoadingState {
  Idle
  Loading
  Error(String)
  Success
}

/// Application model with todo list support
pub type Model {
  Model(
    count: Int,
    error: String,
    todos: List(Todo),
    loading_state: LoadingState,
  )
}

/// Default/initial model
pub fn default() -> Model {
  Model(
    count: 0,
    error: "",
    todos: [],
    loading_state: Idle,
  )
}

/// Helper: Increment counter
pub fn increment(m: Model) -> Model {
  Model(..m, count: m.count + 1)
}

/// Helper: Decrement counter
pub fn decrement(m: Model) -> Model {
  Model(..m, count: m.count - 1)
}

/// Helper: Reset counter
pub fn reset(m: Model) -> Model {
  Model(..m, count: 0)
}
