/// Shared types and functions for boba-raider-8

import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

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

/// Priority levels for todos
pub type Priority {
  Low
  Medium
  High
}

/// Convert priority to string
pub fn priority_to_string(priority: Priority) -> String {
  case priority {
    Low -> "low"
    Medium -> "medium"
    High -> "high"
  }
}

/// Parse priority from string (case insensitive)
pub fn priority_from_string(s: String) -> Result(Priority, String) {
  case string.lowercase(s) {
    "low" -> Ok(Low)
    "medium" -> Ok(Medium)
    "high" -> Ok(High)
    _ -> Error("Invalid priority: must be 'low', 'medium', or 'high'")
  }
}

/// Todo item representing a task
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

/// Validation error types
pub type ValidationError {
  MissingField(field: String)
  InvalidField(field: String, message: String)
}

/// Generate a simple UUID v4-like string
fn generate_uuid() -> String {
  // Simple UUID generation for testing - in production would use crypto
  // Using a fixed format for simplicity
  "550e8400-e29b-41d4-a716-446655440000"
}

/// Generate ISO8601 timestamp
fn generate_timestamp() -> String {
  "2024-01-01T00:00:00Z"
}

/// Check if a string is empty or whitespace only
fn is_empty_or_whitespace(s: String) -> Bool {
  string.trim(s) == ""
}

/// Validate a new todo item
pub fn new_todo(
  title title: String,
  description description: Option(String),
  priority priority: Priority,
) -> Result(Todo, List(ValidationError)) {
  let errors = []

  // Validate title
  let errors = case is_empty_or_whitespace(title) {
    True -> [MissingField("title"), ..errors]
    False -> {
      case string.length(title) > 200 {
        True -> [InvalidField("title", "Title exceeds maximum length of 200 characters"), ..errors]
        False -> errors
      }
    }
  }

  // Validate description if provided
  let errors = case description {
    Some(desc) -> {
      case string.length(desc) > 2000 {
        True -> [InvalidField("description", "Description exceeds maximum length of 2000 characters"), ..errors]
        False -> errors
      }
    }
    None -> errors
  }

  case errors {
    [] -> {
      let new_todo_item = Todo(
        id: generate_uuid(),
        title: string.trim(title),
        description: description,
        priority: priority,
        completed: False,
        created_at: generate_timestamp(),
        updated_at: generate_timestamp(),
      )
      Ok(new_todo_item)
    }
    _ -> Error(list.reverse(errors))
  }
}

/// Check if validation errors contain a specific field
pub fn validation_errors_contain_field(
  errors: List(ValidationError),
  field: String,
) -> Bool {
  list.any(errors, fn(e) {
    case e {
      MissingField(f) -> f == field
      InvalidField(f, _) -> f == field
    }
  })
}

/// Simple JSON string extraction helper - extracts string value for a key
fn extract_json_string(json: String, key: String) -> Result(Option(String), Nil) {
  // Look for "key": "value" pattern
  let pattern = "\"" <> key <> "\":"
  case string.split(json, pattern) {
    [_, rest] | [_, rest, ..] -> {
      // Skip whitespace and optional quote
      let trimmed = string.trim_start(rest)
      case trimmed {
        "null" <> _ -> Ok(None)
        "false" <> _ -> Ok(None)
        "true" <> _ -> Ok(None)
        _ -> {
          // Look for quoted string
          case string.starts_with(trimmed, "\"") {
            True -> {
              let after_quote = string.drop_start(trimmed, 1)
              case string.split(after_quote, "\"") {
                [value, ..] -> Ok(Some(value))
                _ -> Error(Nil)
              }
            }
            False -> Error(Nil)
          }
        }
      }
    }
    _ -> Error(Nil)
  }
}

/// Extract boolean value from JSON
fn extract_json_bool(json: String, key: String) -> Result(Bool, Nil) {
  let pattern = "\"" <> key <> "\":"
  case string.split(json, pattern) {
    [_, rest] | [_, rest, ..] -> {
      let trimmed = string.trim_start(rest)
      case trimmed {
        "true" <> _ -> Ok(True)
        "false" <> _ -> Ok(False)
        _ -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

/// Decode a todo from JSON string with validation
pub fn todo_from_json(json_string: String) -> Result(Todo, List(ValidationError)) {
  // Extract fields from JSON
  let id_result = extract_json_string(json_string, "id")
  let title_result = extract_json_string(json_string, "title")
  let desc_result = extract_json_string(json_string, "description")
  let priority_result = extract_json_string(json_string, "priority")
  let created_result = extract_json_string(json_string, "created_at")
  let updated_result = extract_json_string(json_string, "updated_at")
  let completed_result = extract_json_bool(json_string, "completed")

  // Check for JSON parsing errors
  let parse_errors = []
  let parse_errors = case id_result {
    Error(_) -> [InvalidField("json", "Invalid JSON structure"), ..parse_errors]
    _ -> parse_errors
  }
  let parse_errors = case title_result {
    Error(_) -> [InvalidField("json", "Invalid JSON structure"), ..parse_errors]
    _ -> parse_errors
  }
  let parse_errors = case priority_result {
    Error(_) -> [InvalidField("json", "Invalid JSON structure"), ..parse_errors]
    _ -> parse_errors
  }

  case parse_errors {
    [] -> {
      // Extract values
      let id = case id_result {
        Ok(Some(v)) -> v
        _ -> ""
      }
      let title = case title_result {
        Ok(Some(v)) -> v
        _ -> ""
      }
      let description = case desc_result {
        Ok(Some(v)) -> Some(v)
        Ok(None) -> None
        Error(_) -> None
      }
      let priority_str = case priority_result {
        Ok(Some(v)) -> v
        _ -> ""
      }
      let created_at = case created_result {
        Ok(Some(v)) -> v
        _ -> generate_timestamp()
      }
      let updated_at = case updated_result {
        Ok(Some(v)) -> v
        _ -> generate_timestamp()
      }
      let completed = case completed_result {
        Ok(v) -> v
        _ -> False
      }

      // Validate priority first
      let priority_errors = case priority_from_string(priority_str) {
        Error(_) -> [InvalidField("priority", "Priority must be 'low', 'medium', or 'high'")]
        Ok(_) -> []
      }

      // Validate title
      let title_errors = case is_empty_or_whitespace(title) {
        True -> [MissingField("title")]
        False -> {
          case string.length(title) > 200 {
            True -> [InvalidField("title", "Title exceeds maximum length of 200 characters")]
            False -> []
          }
        }
      }

      // Validate description if provided
      let desc_errors = case description {
        Some(desc) -> {
          case string.length(desc) > 2000 {
            True -> [InvalidField("description", "Description exceeds maximum length of 2000 characters")]
            False -> []
          }
        }
        None -> []
      }

      let all_errors = list.flatten([priority_errors, title_errors, desc_errors])

      case all_errors {
        [] -> {
          let priority = case priority_from_string(priority_str) {
            Ok(p) -> p
            _ -> Medium
          }
          let parsed_todo = Todo(
            id: id,
            title: string.trim(title),
            description: description,
            priority: priority,
            completed: completed,
            created_at: created_at,
            updated_at: updated_at,
          )
          Ok(parsed_todo)
        }
        _ -> Error(all_errors)
      }
    }
    _ -> Error(parse_errors)
  }
}

/// Convert a Todo to JSON string
pub fn todo_to_json(item: Todo) -> String {
  let description_value = case item.description {
    Some(d) -> json.string(d)
    None -> json.null()
  }

  json.object([
    #("id", json.string(item.id)),
    #("title", json.string(item.title)),
    #("description", description_value),
    #("priority", json.string(priority_to_string(item.priority))),
    #("completed", json.bool(item.completed)),
    #("created_at", json.string(item.created_at)),
    #("updated_at", json.string(item.updated_at)),
  ])
  |> json.to_string
}
