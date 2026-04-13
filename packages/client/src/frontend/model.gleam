import shared.{type Todo}

/// Application state

pub type Model {
  Model(todos: List(Todo), error: String)
}

pub fn default() -> Model {
  Model(todos: [], error: "")
}
