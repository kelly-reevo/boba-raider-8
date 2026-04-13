/// Application state for todo list UI

import gleam/list
import shared.{type Todo}

/// Filter options for todos
pub type Filter {
  All
  Active
  Completed
}

/// Data loading state
pub type DataState {
  Loading
  Loaded
  Error(String)
}

/// Application model
pub type Model {
  Model(
    todos: List(Todo),
    filter: Filter,
    data_state: DataState,
  )
}

/// Default initial state
pub fn default() -> Model {
  Model(
    todos: [],
    filter: All,
    data_state: Loading,
  )
}

/// Filter todos based on current filter setting
pub fn filter_todos(todos: List(Todo), filter: Filter) -> List(Todo) {
  case filter {
    All -> todos
    Active -> list.filter(todos, fn(t) { !t.completed })
    Completed -> list.filter(todos, fn(t) { t.completed })
  }
}
