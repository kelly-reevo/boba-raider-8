import shared.{type Todo}

/// Fetch status for loading state tracking
pub type FetchStatus {
  Idle
  Loading
  Success
  Error(String)
}

/// Application state
pub type Model {
  Model(
    todos: List(Todo),
    status: FetchStatus,
  )
}

pub fn default() -> Model {
  Model(todos: [], status: Idle)
}
