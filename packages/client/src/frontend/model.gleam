/// Application state

import shared

pub type Model {
  Model(
    todos: List(shared.Todo),
    form_title: String,
    form_description: String,
    form_error: String,
    loading: Bool,
  )
}

pub fn default() -> Model {
  Model(
    todos: [],
    form_title: "",
    form_description: "",
    form_error: "",
    loading: False,
  )
}
