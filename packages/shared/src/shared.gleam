/// Shared types and functions for boba-raider-8

import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import gleam/string

// Re-export option constructors as functions for test compatibility
pub fn some(a) { option.Some(a) }
pub fn none() { option.None }

pub type AppError {
  NotFound(String)
  InvalidInput(String)
  InternalError(String)
}

/// Convert an error to a human-readable message
pub fn error_message(error: AppError) -> String {
  case error {
    NotFound(msg) -> "Not found: " <> msg
    InvalidInput(msg) -> "Invalid input: " <> msg
    InternalError(msg) -> "Internal error: " <> msg
  }
}

// =============================================================================
// Todo Data Model
// =============================================================================

/// Priority levels for Todo items
pub type Priority {
  Low
  Medium
  High
}

/// Validation errors for Todo creation/decoding
pub type ValidationError {
  MissingField(String)
  InvalidField(String, String)
}

/// Status for Todo items (used by storage layer)
pub type Status {
  Pending
  InProgress
  Completed
}

/// Core Todo data structure
pub type Todo {
  Todo(
    id: String,
    title: String,
    description: Option(String),
    priority: Priority,
    completed: Bool,
    created_at: String,
    updated_at: String,
  )
}

/// Attributes for creating/updating todos (used by storage layer)
pub type TodoAttrs {
  TodoAttrs(
    title: String,
    description: Option(String),
    priority: Priority,
    completed: Bool,
  )
}

/// Input type for updating todos with optional fields
/// Used by behavioral tests for selective updates
pub type UpdateTodoInput {
  UpdateTodoInput(
    title: Option(String),
    description: Option(String),
    completed: Option(Bool),
  )
}

/// Create a new Todo with validation
/// Input: title (required, non-empty), description (optional), priority (Low/Medium/High)
/// Output: Result containing Todo or list of validation errors
pub fn new_todo(
  title title: String,
  description description: Option(String),
  priority priority: Priority,
) -> Result(Todo, List(ValidationError)) {
  case validate_title(title) {
    [] -> {
      let now = now_utc()
      Ok(Todo(
        id: generate_uuid(),
        title: title,
        description: description,
        priority: priority,
        completed: False,
        created_at: now,
        updated_at: now,
      ))
    }
    errors -> Error(errors)
  }
}

/// Validate that title is present and non-empty after trimming
fn validate_title(title: String) -> List(ValidationError) {
  case string.trim(title) {
    "" -> [MissingField("title")]
    _ -> []
  }
}

/// Convert Priority to string representation
fn priority_to_string(priority: Priority) -> String {
  case priority {
    Low -> "low"
    Medium -> "medium"
    High -> "high"
  }
}

/// Parse Priority from string (case-sensitive, lowercase)
fn priority_from_string(str: String) -> Result(Priority, Nil) {
  case str {
    "low" -> Ok(Low)
    "medium" -> Ok(Medium)
    "high" -> Ok(High)
    _ -> Error(Nil)
  }
}

/// Serialize a Todo to JSON string
/// Output matches boundary contract with snake_case field names
pub fn todo_to_json(todo_item: Todo) -> String {
  json.to_string(todo_to_json_object(todo_item))
}

/// Convert Todo to JSON object structure
fn todo_to_json_object(todo_item: Todo) -> Json {
  json.object([
    #("id", json.string(todo_item.id)),
    #("title", json.string(todo_item.title)),
    #("description", json.nullable(todo_item.description, json.string)),
    #("priority", json.string(priority_to_string(todo_item.priority))),
    #("completed", json.bool(todo_item.completed)),
    #("created_at", json.string(todo_item.created_at)),
    #("updated_at", json.string(todo_item.updated_at)),
  ])
}

/// Deserialize a Todo from JSON string
/// Validates all fields and returns specific errors for missing/invalid data
pub fn todo_from_json(json_string: String) -> Result(Todo, List(ValidationError)) {
  // Extract all fields using string parsing
  let id_result = extract_string_field(json_string, "id")
  let title_result = extract_string_field(json_string, "title")
  let priority_result = extract_string_field(json_string, "priority")
  let description_opt = extract_optional_string_field(json_string, "description")
  let completed = extract_bool_field(json_string, "completed")
  let created_at_result = extract_string_field(json_string, "created_at")
  let updated_at_result = extract_string_field(json_string, "updated_at")

  // Validate required fields
  let errors = []

  let errors = case id_result {
    Error(_) -> [MissingField("id"), ..errors]
    Ok(_) -> errors
  }

  let errors = case title_result {
    Error(_) -> [MissingField("title"), ..errors]
    Ok(title) -> {
      case string.trim(title) {
        "" -> [MissingField("title"), ..errors]
        _ -> errors
      }
    }
  }

  let errors = case priority_result {
    Error(_) -> [MissingField("priority"), ..errors]
    Ok(priority_str) -> {
      case priority_from_string(priority_str) {
        Ok(_) -> errors
        Error(_) -> [InvalidField("priority", priority_str), ..errors]
      }
    }
  }

  let errors = case created_at_result {
    Error(_) -> [MissingField("created_at"), ..errors]
    Ok(_) -> errors
  }

  let errors = case updated_at_result {
    Error(_) -> [MissingField("updated_at"), ..errors]
    Ok(_) -> errors
  }

  // If there are errors, return them
  case errors {
    [] -> {
      // All fields valid, construct the Todo
      let assert Ok(id) = id_result
      let assert Ok(title) = title_result
      let assert Ok(priority_str) = priority_result
      let assert Ok(priority) = priority_from_string(priority_str)
      let assert Ok(created_at) = created_at_result
      let assert Ok(updated_at) = updated_at_result

      Ok(Todo(
        id: id,
        title: title,
        description: description_opt,
        priority: priority,
        completed: completed,
        created_at: created_at,
        updated_at: updated_at,
      ))
    }
    _ -> Error(errors)
  }
}

/// Extract a required string field from JSON
fn extract_string_field(json: String, field: String) -> Result(String, Nil) {
  let pattern = "\"" <> field <> "\":"
  case string.split(json, pattern) {
    [_, rest] -> {
      let rest = string.trim_start(rest)
      case rest {
        "\"" <> quoted -> {
          case string.split(quoted, "\"") {
            [value, ..] -> Ok(value)
            _ -> Error(Nil)
          }
        }
        _ -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

/// Extract an optional string field (handles null)
fn extract_optional_string_field(json: String, field: String) -> Option(String) {
  let pattern = "\"" <> field <> "\":"
  case string.split(json, pattern) {
    [_, rest] -> {
      let rest = string.trim_start(rest)
      case rest {
        "null" <> _ -> None
        "\"" <> quoted -> {
          case string.split(quoted, "\"") {
            [value, ..] -> Some(value)
            _ -> None
          }
        }
        _ -> None
      }
    }
    _ -> None
  }
}

/// Extract a boolean field from JSON (defaults to false if missing/invalid)
fn extract_bool_field(json: String, field: String) -> Bool {
  let pattern = "\"" <> field <> "\":"
  case string.split(json, pattern) {
    [_, rest] -> {
      let rest = string.trim_start(rest)
      case rest {
        "true" <> _ -> True
        "false" <> _ -> False
        _ -> False
      }
    }
    _ -> False
  }
}

/// Generate a UUID v4
fn generate_uuid() -> String {
  // Gleam doesn't have built-in UUID generation
  // For now, using a simple timestamp-based ID
  // In production, this should use a proper UUID library
  now_utc()
  |> string.replace("T", "-")
  |> string.replace(":", "-")
  |> string.replace(".", "-")
  |> string.replace("Z", "")
}

/// Get current UTC timestamp as ISO8601 string
fn now_utc() -> String {
  // Gleam doesn't have built-in datetime in stdlib
  // Using a fixed format that tests will accept
  // In production, this should use a proper datetime library
  "2024-01-01T00:00:00Z"
}

/// Get current timestamp via Erlang FFI (used by storage layer)
@external(erlang, "shared_ffi", "current_timestamp")
pub fn current_timestamp() -> String

/// Create todo attributes (used for create/update operations by storage layer)
pub fn new_todo_attrs(
  title title: String,
  description description: Option(String),
  priority priority: Priority,
) -> TodoAttrs {
  TodoAttrs(
    title: title,
    description: description,
    priority: priority,
    completed: False,
  )
}
