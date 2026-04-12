/// Todo data model with validation functions

import gleam/float
import gleam/string
import gleam/time/timestamp

/// Priority levels for todos
pub type Priority {
  Low
  Medium
  High
}

/// Todo item data structure
pub type Todo {
  Todo(
    id: String,
    title: String,
    description: String,
    priority: Priority,
    completed: Bool,
  )
}

/// Validation error structure
pub type ValidationError {
  ValidationError(field: String, message: String)
}

/// Generate a unique ID using timestamp
fn generate_id() -> String {
  let now = timestamp.system_time()
  let ts = timestamp.to_unix_seconds(now)
  "todo-" <> float.to_string(ts)
}

/// Validate that title is non-empty
fn validate_title(title: String) -> List(ValidationError) {
  case string.is_empty(title) {
    True -> [ValidationError("title", "Title is required")]
    False -> []
  }
}

/// Validate a priority string and return the Priority enum
pub fn validate_priority(priority_str: String) -> Result(Priority, List(ValidationError)) {
  case string.lowercase(priority_str) {
    "low" -> Ok(Low)
    "medium" -> Ok(Medium)
    "high" -> Ok(High)
    _ -> Error([ValidationError("priority", "Invalid priority value")])
  }
}

/// Create a new todo with validation
pub fn create_todo(
  title: String,
  description: String,
  priority: Priority,
) -> Result(Todo, List(ValidationError)) {
  let errors = validate_title(title)

  case errors {
    [] -> Ok(Todo(
      id: generate_id(),
      title: title,
      description: description,
      priority: priority,
      completed: False,
    ))
    _ -> Error(errors)
  }
}
