/// Shared types and functions for boba-raider-8

import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

// ============================================================================
// App Error Types
// ============================================================================

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

// ============================================================================
// Todo Data Model
// ============================================================================

/// Priority enum: low | medium | high
pub type Priority {
  Low
  Medium
  High
}

/// Convert Priority to string (lowercase for JSON)
pub fn priority_to_string(priority: Priority) -> String {
  case priority {
    Low -> "low"
    Medium -> "medium"
    High -> "high"
  }
}

/// Parse Priority from string
pub fn priority_from_string(str: String) -> Result(Priority, String) {
  case string.lowercase(str) {
    "low" -> Ok(Low)
    "medium" -> Ok(Medium)
    "high" -> Ok(High)
    _ -> Error("Invalid priority: " <> str)
  }
}

/// Todo type per boundary contract
/// - id: string (UUID v4, server-generated)
/// - title: string (1-200 chars, required)
/// - description: string | null (max 2000 chars, optional)
/// - priority: 'low' | 'medium' | 'high'
/// - completed: boolean (default: false)
/// - created_at: string (ISO8601, server-generated)
/// - updated_at: string (ISO8601, server-generated)
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

/// Validation error type with variants for different error types
pub type ValidationError {
  MissingField(field: String)
  InvalidField(field: String, message: String)
}

// ============================================================================
// Validation Functions
// ============================================================================

/// Validate title: required, 1-200 chars
fn validate_title(title: String) -> Result(String, List(ValidationError)) {
  let trimmed = string.trim(title)
  let len = string.length(trimmed)

  case trimmed {
    "" -> Error([MissingField("title")])
    _ if len > 200 -> Error([InvalidField("title", "Title exceeds maximum length of 200 characters")])
    _ -> Ok(trimmed)
  }
}

/// Validate description: optional, max 2000 chars
fn validate_description(desc: Option(String)) -> Result(Option(String), List(ValidationError)) {
  case desc {
    None -> Ok(None)
    Some(text) -> {
      let len = string.length(text)
      case len > 2000 {
        True -> Error([InvalidField("description", "Description exceeds maximum length of 2000 characters")])
        False -> Ok(Some(text))
      }
    }
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

// ============================================================================
// Server-side Generation
// ============================================================================

/// Generate a UUID v4
/// Format: 8-4-4-4-12 hexadecimal characters
/// Example: 550e8400-e29b-41d4-a716-446655440000
fn generate_uuid_v4() -> String {
  // Generate random hex segments using timestamp as seed
  let segment1 = random_hex(8)
  let segment2 = random_hex(4)
  // UUID v4 variant: 4xxx where x is 8,9,a,b
  let segment3 = "4" <> random_hex(3)
  // UUID variant: 8xxx, 9xxx, axxx, bxxx
  let variant_char = case random_int(4) {
    0 -> "8"
    1 -> "9"
    2 -> "a"
    _ -> "b"
  }
  let segment4 = variant_char <> random_hex(3)
  let segment5 = random_hex(12)

  segment1 <> "-" <> segment2 <> "-" <> segment3 <> "-" <> segment4 <> "-" <> segment5
}

/// Generate random hex string of given length
fn random_hex(length: Int) -> String {
  case length {
    0 -> ""
    n -> random_hex_char() <> random_hex(n - 1)
  }
}

/// Generate a single random hex character
fn random_hex_char() -> String {
  let chars = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"]
  let index = random_int(16)
  case list.drop(chars, index) {
    [char, ..] -> char
    [] -> "0"
  }
}

/// Generate random integer (0 to max-1)
/// Uses timestamp-based pseudo-random for simplicity
fn random_int(max: Int) -> Int {
  // Use current time to generate pseudo-random values
  let timestamp = system_time_millisecond()
  let hash = timestamp % max
  case hash < 0 {
    True -> 0 - hash
    False -> hash
  }
}

/// Atoms for time units
fn atom_millisecond() -> Atom {
  atom_from_string("millisecond")
}

@external(erlang, "erlang", "binary_to_atom")
fn atom_from_string(binary: String) -> Atom

type Atom

/// Get current timestamp in milliseconds
fn system_time_millisecond() -> Int {
  system_time(atom_millisecond())
}

@external(erlang, "shared_ffi", "system_time")
fn system_time(unit: Atom) -> Int

@external(erlang, "shared_ffi", "int_to_string")
fn int_to_string(n: Int) -> String

/// Generate ISO8601 timestamp string
pub fn generate_timestamp() -> String {
  let now = system_time_millisecond() / 1000
  format_iso8601(now)
}

/// Format seconds since epoch as ISO8601 UTC
/// Example: 2024-01-15T10:30:00Z
fn format_iso8601(seconds: Int) -> String {
  // Simple ISO8601 formatting from seconds
  let days_since_epoch = seconds / 86400
  let seconds_in_day = seconds % 86400

  // Calculate date components (simplified - using approximate calculations)
  let year = 1970 + days_since_epoch / 365
  let day_of_year = days_since_epoch % 365

  // Approximate month/day calculation
  let month = day_of_year / 30 + 1
  let day = day_of_year % 30 + 1

  let hour = seconds_in_day / 3600
  let minute = {seconds_in_day % 3600} / 60
  let second = seconds_in_day % 60

  // Format as YYYY-MM-DDTHH:MM:SSZ
  int_to_padded_string(year, 4) <> "-" <> int_to_padded_string(month, 2) <> "-" <> int_to_padded_string(day, 2) <> "T" <> int_to_padded_string(hour, 2) <> ":" <> int_to_padded_string(minute, 2) <> ":" <> int_to_padded_string(second, 2) <> "Z"
}

/// Convert integer to zero-padded string
fn int_to_padded_string(n: Int, width: Int) -> String {
  let str = int_to_string(n)
  let len = string.length(str)
  case len >= width {
    True -> str
    False -> string.repeat("0", width - len) <> str
  }
}

// ============================================================================
// Public API
// ============================================================================

/// Create a new Todo with server-generated fields
/// - id: auto-generated UUID v4
/// - created_at: auto-generated ISO8601 timestamp
/// - updated_at: auto-generated ISO8601 timestamp (same as created_at on creation)
pub fn new_todo(
  title title: String,
  description description: Option(String),
  priority priority: Priority,
) -> Result(Todo, List(ValidationError)) {
  // Validate title
  case validate_title(title) {
    Error(errors) -> Error(errors)
    Ok(validated_title) -> {
      // Validate description
      case validate_description(description) {
        Error(errors) -> Error(errors)
        Ok(validated_desc) -> {
          // Generate server-side fields
          let id = generate_uuid_v4()
          let timestamp = generate_timestamp()

          Ok(Todo(
            id: id,
            title: validated_title,
            description: validated_desc,
            priority: priority,
            completed: False,
            created_at: timestamp,
            updated_at: timestamp,
          ))
        }
      }
    }
  }
}

/// Serialize Todo to JSON string
pub fn todo_to_json(todo_val: Todo) -> String {
  let description_value = case todo_val.description {
    Some(desc) -> json.string(desc)
    None -> json.null()
  }

  json.object([
    #("id", json.string(todo_val.id)),
    #("title", json.string(todo_val.title)),
    #("description", description_value),
    #("priority", json.string(priority_to_string(todo_val.priority))),
    #("completed", json.bool(todo_val.completed)),
    #("created_at", json.string(todo_val.created_at)),
    #("updated_at", json.string(todo_val.updated_at)),
  ])
  |> json.to_string()
}

/// JSON decoder for optional string (null -> None)
fn optional_string_decoder() -> decode.Decoder(Option(String)) {
  decode.optional(decode.string)
}

/// JSON decoder for Priority
fn priority_decoder() -> decode.Decoder(Priority) {
  decode.string
  |> decode.then(fn(str) {
    case priority_from_string(str) {
      Ok(p) -> decode.success(p)
      Error(_) -> decode.failure(Medium, "Expected 'low', 'medium', or 'high'")
    }
  })
}

/// JSON decoder for Todo
fn todo_decoder() -> decode.Decoder(Todo) {
  use id <- decode.field("id", decode.string)
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", optional_string_decoder())
  use priority <- decode.field("priority", priority_decoder())
  use completed <- decode.field("completed", decode.bool)
  use created_at <- decode.field("created_at", decode.string)
  use updated_at <- decode.field("updated_at", decode.string)

  decode.success(Todo(
    id: id,
    title: title,
    description: description,
    priority: priority,
    completed: completed,
    created_at: created_at,
    updated_at: updated_at,
  ))
}

/// Deserialize JSON string to Todo with validation
pub fn todo_from_json(json_str: String) -> Result(Todo, List(ValidationError)) {
  case json.parse(json_str, todo_decoder()) {
    Ok(t) -> Ok(t)
    Error(_) -> {
      // Try to extract fields and provide specific validation errors
      let id_result = extract_json_string(json_str, "id")
      let title_result = extract_json_string(json_str, "title")
      let priority_result = extract_json_string(json_str, "priority")

      let errors = []

      // Check for missing/invalid fields
      let errors = case title_result {
        Ok(None) | Error(_) -> [MissingField("title"), ..errors]
        Ok(Some("")) -> [MissingField("title"), ..errors]
        Ok(Some(t)) -> {
          case string.length(t) > 200 {
            True -> [InvalidField("title", "Title exceeds maximum length of 200 characters"), ..errors]
            False -> errors
          }
        }
      }

      let errors = case priority_result {
        Ok(None) | Error(_) -> [InvalidField("priority", "Priority must be 'low', 'medium', or 'high'"), ..errors]
        Ok(Some(p)) -> {
          case priority_from_string(p) {
            Ok(_) -> errors
            Error(_) -> [InvalidField("priority", "Priority must be 'low', 'medium', or 'high'"), ..errors]
          }
        }
      }

      let errors = case id_result {
        Ok(None) | Error(_) -> [MissingField("id"), ..errors]
        _ -> errors
      }

      case errors {
        [] -> Error([InvalidField("json", "Invalid JSON structure")])
        _ -> Error(list.reverse(errors))
      }
    }
  }
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
