/// Application state for todo management with empty state UI support

import gleam/list
import gleam/option.{type Option}
import shared.{type Todo}

/// Filter options for todo list
pub type Filter {
  All
  Active
  Completed
}

/// Loading state for async operations
pub type LoadingState {
  Idle
  Loading
  Error(String)
  Loaded
}

/// Application model containing todos, filter state, and UI state
pub type Model {
  Model(
    todos: List(Todo),
    filter: Filter,
    loading: LoadingState,
    new_todo_title: String,
    new_todo_description: String,
  )
}

/// Default/initial model state
pub fn default() -> Model {
  Model(
    todos: [],
    filter: All,
    loading: Idle,
    new_todo_title: "",
    new_todo_description: "",
  )
}

/// Get filtered todos based on current filter setting
pub fn get_filtered_todos(model: Model) -> List(Todo) {
  case model.filter {
    All -> model.todos
    Active -> filter_by_completed(model.todos, False)
    Completed -> filter_by_completed(model.todos, True)
  }
}

/// Filter todos by completion status
fn filter_by_completed(todos: List(Todo), completed: Bool) -> List(Todo) {
  todos
  |> list.filter(fn(todo_item) { todo_item.completed == completed })
}

/// Check if the current filtered view is empty
pub fn is_filtered_empty(model: Model) -> Bool {
  get_filtered_todos(model) |> list.is_empty
}

/// Get the appropriate empty state message based on filter
pub fn get_empty_message(model: Model) -> String {
  case model.filter {
    All -> "No todos yet. Add your first todo above!"
    Active -> "No active todos"
    Completed -> "No completed todos"
  }
}
