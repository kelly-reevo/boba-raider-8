/// Application state

import shared.{type Todo}

pub type Filter {
  All
  Active
  Completed
}

pub type Model {
  Model(
    todos: List(Todo),
    filter: Filter,
    error: String,
    loading: Bool,
  )
}

pub fn default() -> Model {
  Model(todos: [], filter: All, error: "", loading: False)
}
