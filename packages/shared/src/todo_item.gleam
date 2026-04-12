/// Todo item types for shared use

import gleam/option.{type Option}

/// Todo item data structure - matches the Todo type in shared.gleam
/// but exported as TodoItem for module clarity
pub type TodoItem {
  TodoItem(
    id: String,
    title: String,
    description: Option(String),
    priority: String,
    completed: Bool,
    created_at: Int,
  )
}
