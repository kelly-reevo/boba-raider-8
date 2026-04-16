/// Todo filtering logic and types for the frontend

import gleam/list
import shared.{type Todo}

/// Filter variants for todo list filtering
pub type FilterState {
  All
  Active
  Completed
}

/// Filter a list of todos based on the filter state.
/// - All: returns all todos regardless of completion status
/// - Active: returns only todos with completed=False
/// - Completed: returns only todos with completed=True
pub fn filter_todos(todos: List(Todo), filter: FilterState) -> List(Todo) {
  case filter {
    All -> todos
    Active -> list.filter(todos, fn(t) { !t.completed })
    Completed -> list.filter(todos, fn(t) { t.completed })
  }
}
