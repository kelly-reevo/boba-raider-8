/// Application state

import shared.{type Todo}

/// Filter options for todo list
pub type Filter {
  All
  Active
  Completed
}

/// Application model containing todos and filter state
pub type Model {
  Model(
    todos: List(Todo),
    filter: Filter,
    loading: Bool,
    error: String,
  )
}

/// Default initial state
pub fn default() -> Model {
  Model(todos: [], filter: All, loading: False, error: "")
}
