/// Application state

import gleam/option.{type Option, None}
import shared.{type Todo}

pub type Model {
  Model(
    count: Int,
    error: String,
    todos: List(Todo),
    loading: Bool,
    deleting_id: Option(String),
  )
}

pub fn default() -> Model {
  Model(count: 0, error: "", todos: [], loading: False, deleting_id: None)
}
