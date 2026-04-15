/// Application state for the todo app
/// Types are re-exported from filter module

import frontend/filter

// Re-export types from filter for test compatibility
pub type Filter = filter.Filter

pub type TodoItem = filter.TodoItem

/// Application model containing todos, current filter, and input text
pub type Model {
  Model(
    todos: List(TodoItem),
    filter: Filter,
    input_text: String,
  )
}

/// Default empty model state
pub fn default() -> Model {
  Model(todos: [], filter: filter.All, input_text: "")
}
