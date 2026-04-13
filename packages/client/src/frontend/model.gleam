import shared.{type Todo}

/// Application state
pub type Model {
  Model(
    todos: List(Todo),
    loading: Bool,
    error: String,
  )
}

pub fn default() -> Model {
  Model(
    todos: [],
    loading: False,
    error: "",
  )
}
