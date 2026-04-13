/// Todo data model with validation functions
/// Note: Types are now defined in shared.gleam and re-exported here for backward compatibility

import gleam/float
import gleam/option.{None, Some}
import gleam/string
import gleam/time/timestamp
import shared.{type Priority, type Todo, Todo, type ValidationError, ValidationError, Low, Medium, High}

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

/// Priority to string helper
fn priority_to_string(priority: Priority) -> String {
  case priority {
    Low -> "low"
    Medium -> "medium"
    High -> "high"
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
      description: case description {
        "" -> None
        d -> Some(d)
      },
      priority: priority_to_string(priority),
      completed: False,
      created_at: 0,
      updated_at: 0,
    ))
    _ -> Error(errors)
  }
}
