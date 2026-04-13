import shared.{type Todo}

/// Application state
pub type Model {
  Model(
    todos: List(Todo),
    loading: Bool,
    toggling_id: String,
    error: String,
  )
}

/// Create default initial model
pub fn default() -> Model {
  Model(
    todos: [],
    loading: False,
    toggling_id: "",
    error: "",
  )
}
