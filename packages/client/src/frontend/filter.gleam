/// Todo filtering logic and types for the frontend

import gleam/bool
import gleam/list

/// Filter variants for todo list filtering
pub type Filter {
  All
  Active
  Completed
}

/// Represents a todo item with all its fields
pub type TodoItem {
  TodoItem(
    id: String,
    title: String,
    description: String,
    priority: String,
    completed: Bool,
    created_at: String,
    updated_at: String,
  )
}

/// Filter a list of todos based on the current filter state.
/// - All: returns all todos regardless of completion status
/// - Active: returns only todos with completed=False
/// - Completed: returns only todos with completed=True
pub fn filter_todos(todos: List(TodoItem), filter: Filter) -> List(TodoItem) {
  case filter {
    All -> todos
    Active -> list.filter(todos, fn(t) { bool.negate(t.completed) })
    Completed -> list.filter(todos, fn(t) { t.completed })
  }
}
