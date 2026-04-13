/// Todo data model
/// Boundary contract: {id: string, title: string, description: string|null, priority: 'low'|'medium'|'high', completed: boolean, created_at: datetime}

import gleam/option.{type Option}

/// Priority levels for todos
pub type Priority {
  Low
  Medium
  High
}

/// Convert priority to string representation
pub fn priority_to_string(priority: Priority) -> String {
  case priority {
    Low -> "low"
    Medium -> "medium"
    High -> "high"
  }
}

/// Parse priority from string
pub fn parse_priority(s: String) -> Priority {
  case s {
    "low" -> Low
    "medium" -> Medium
    "high" -> High
    _ -> Medium
  }
}

/// Todo item structure
/// - id: UUID string
/// - title: Non-empty string
/// - description: Optional string (None represents null)
/// - priority: Low | Medium | High
/// - completed: Boolean
/// - created_at: Unix timestamp (milliseconds)
/// - updated_at: Unix timestamp (milliseconds)
pub type Todo {
  Todo(
    id: String,
    title: String,
    description: Option(String),
    priority: Priority,
    completed: Bool,
    created_at: Int,
    updated_at: Int,
  )
}

/// Create a new todo with the given fields
/// Uses current timestamp for created_at and updated_at
pub fn new(
  id: String,
  title: String,
  description: Option(String),
  priority: Priority,
  created_at: Int,
) -> Todo {
  Todo(
    id: id,
    title: title,
    description: description,
    priority: priority,
    completed: False,
    created_at: created_at,
    updated_at: created_at,
  )
}

/// Toggle the completed status of a todo
pub fn toggle(item: Todo) -> Todo {
  Todo(..item, completed: !item.completed)
}

/// Update a todo's title
pub fn set_title(item: Todo, title: String) -> Todo {
  Todo(..item, title: title)
}

/// Update a todo's description
pub fn set_description(item: Todo, description: Option(String)) -> Todo {
  Todo(..item, description: description)
}

/// Update a todo's priority
pub fn set_priority(item: Todo, priority: Priority) -> Todo {
  Todo(..item, priority: priority)
}
