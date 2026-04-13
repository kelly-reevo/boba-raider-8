/// Application state

import shared.{type Todo}

pub type Model {
  Model(todos: List(Todo), error: String, loading: Bool)
}

pub fn default() -> Model {
  Model(todos: [], error: "", loading: False)
}
