/// Application state

import frontend/todo_types.{type Filter, type Todo, All}

pub type Model {
  Model(
    count: Int,
    error: String,
    current_filter: Filter,
    todos: List(Todo),
    loading: Bool,
  )
}

pub fn default() -> Model {
  Model(count: 0, error: "", current_filter: All, todos: [], loading: False)
}
