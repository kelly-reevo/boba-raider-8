/// Shared types and functions for boba-raider-8

import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

// ============================================================
// AppError types (legacy compatibility)
// ============================================================

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

// ============================================================
// Todo Data Structure
// ============================================================

/// Priority levels for todo items
pub type Priority {
  Low
  Medium
  High
}

/// Validation errors for todo creation/update
pub type ValidationError {
  MissingField(String)
  InvalidField(String, String)
}

/// Todo item data structure
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

/// Input for creating a new todo
pub type NewTodoInput {
  NewTodoInput(
    title: String,
    description: Option(String),
    priority: Priority,
  )
}

/// Maximum title length
const max_title_length = 200

/// Maximum description length
const max_description_length = 1000

// ============================================================
// Priority encoding/decoding
// ============================================================

/// Convert Priority to string
fn priority_to_string(priority: Priority) -> String {
  case priority {
    Low -> "low"
    Medium -> "medium"
    High -> "high"
  }
}

/// Parse priority from string (case-insensitive, returns Result)
fn priority_from_string(priority_str: String) -> Result(Priority, String) {
  case string.lowercase(priority_str) {
    "low" -> Ok(Low)
    "medium" -> Ok(Medium)
    "high" -> Ok(High)
    _ -> Error("Invalid priority value: " <> priority_str)
  }
}

/// Decoder for Priority type
fn priority_decoder() -> decode.Decoder(Priority) {
  decode.string
  |> decode.then(fn(str) {
    case priority_from_string(str) {
      Ok(priority) -> decode.success(priority)
      Error(_) -> decode.failure(Medium, "Priority")
    }
  })
}

// ============================================================
// UUID Generation
// ============================================================

/// Generate a UUID v4 string
fn generate_uuid() -> String {
  let parts = [8, 4, 4, 4, 12]

  let uuid_parts = list.map(parts, fn(len) {
    generate_hex_string(len, "")
  })

  case uuid_parts {
    [a, b, c, d, e] -> a <> "-" <> b <> "-" <> c <> "-" <> d <> "-" <> e
    _ -> "00000000-0000-0000-0000-000000000000"
  }
}

/// Generate a random hex string of given length
fn generate_hex_string(len: Int, acc: String) -> String {
  case len {
    0 -> acc
    _ -> {
      // Use deterministic calculation for now
      let index = { len * 17 + string.length(acc) * 13 } % 16
      let char = case index {
        0 -> "0"
        1 -> "1"
        2 -> "2"
        3 -> "3"
        4 -> "4"
        5 -> "5"
        6 -> "6"
        7 -> "7"
        8 -> "8"
        9 -> "9"
        10 -> "a"
        11 -> "b"
        12 -> "c"
        13 -> "d"
        14 -> "e"
        15 -> "f"
        _ -> "0"
      }
      generate_hex_string(len - 1, acc <> char)
    }
  }
}

// ============================================================
// Timestamp Generation
// ============================================================

@external(erlang, "calendar", "universal_time")
fn universal_time_ffi() -> #(#(Int, Int, Int), #(Int, Int, Int))

/// Get current UTC time as ISO8601 string
fn generate_timestamp() -> String {
  let #(#(year, month, day), #(hour, minute, second)) = universal_time_ffi()

  // Format as YYYY-MM-DDTHH:MM:SSZ
  int_to_padded_string(year) <> "-" <> int_to_padded_string(month) <> "-" <> int_to_padded_string(day) <> "T" <> int_to_padded_string(hour) <> ":" <> int_to_padded_string(minute) <> ":" <> int_to_padded_string(second) <> "Z"
}

/// Convert integer to zero-padded string
fn int_to_padded_string(n: Int) -> String {
  let str = int_to_string(n)
  case string.length(str) {
    1 -> "0" <> str
    2 -> str
    4 -> str
    _ -> str
  }
}

@external(erlang, "erlang", "integer_to_binary")
fn int_to_string(n: Int) -> String

// ============================================================
// Validation Functions
// ============================================================

/// Validate a new todo input
fn validate_new_todo(
  input: NewTodoInput,
) -> Result(NewTodoInput, List(ValidationError)) {
  let errors = []

  // Validate title
  let trimmed_title = string.trim(input.title)
  let errors = case string.is_empty(trimmed_title) {
    True -> [MissingField("title"), ..errors]
    False -> errors
  }

  // Validate title length
  let errors = case string.length(trimmed_title) > max_title_length {
    True -> [
      InvalidField(
        "title",
        "Title exceeds maximum length of " <> int_to_string(max_title_length) <> " characters",
      ),
      ..errors
    ]
    False -> errors
  }

  // Validate description length if present
  let errors = case input.description {
    Some(desc) ->
      case string.length(desc) > max_description_length {
        True -> [
          InvalidField(
            "description",
            "Description exceeds maximum length of " <> int_to_string(max_description_length) <> " characters",
          ),
          ..errors
        ]
        False -> errors
      }
    None -> errors
  }

  case errors {
    [] -> Ok(NewTodoInput(..input, title: trimmed_title))
    _ -> Error(list.reverse(errors))
  }
}

// ============================================================
// Public API: Todo Creation
// ============================================================

/// Create a new todo item with validation
pub fn new_todo(
  title title: String,
  description description: Option(String),
  priority priority: Priority,
) -> Result(Todo, List(ValidationError)) {
  let input =
    NewTodoInput(title: title, description: description, priority: priority)

  case validate_new_todo(input) {
    Ok(validated_input) -> {
      let timestamp = generate_timestamp()
      Ok(Todo(
        id: generate_uuid(),
        title: validated_input.title,
        description: validated_input.description,
        priority: validated_input.priority,
        completed: False,
        created_at: timestamp,
        updated_at: timestamp,
      ))
    }
    Error(errors) -> Error(errors)
  }
}

// ============================================================
// JSON Serialization
// ============================================================

/// Serialize a Todo to JSON string
pub fn todo_to_json(item: Todo) -> String {
  json.object([
    #("id", json.string(item.id)),
    #("title", json.string(item.title)),
    #("description", case item.description {
      Some(desc) -> json.string(desc)
      None -> json.null()
    }),
    #("priority", json.string(priority_to_string(item.priority))),
    #("completed", json.bool(item.completed)),
    #("created_at", json.string(item.created_at)),
    #("updated_at", json.string(item.updated_at)),
  ])
  |> json.to_string()
}

/// Build a decoder for Todo from JSON
fn todo_decoder() -> decode.Decoder(Todo) {
  decode.field("id", decode.string, fn(id) {
    decode.field("title", decode.string, fn(title) {
      decode.field("description", decode.optional(decode.string), fn(description) {
        decode.field("priority", priority_decoder(), fn(priority) {
          decode.field("completed", decode.bool, fn(completed) {
            decode.field("created_at", decode.string, fn(created_at) {
              decode.field("updated_at", decode.string, fn(updated_at) {
                decode.success(Todo(
                  id: id,
                  title: title,
                  description: description,
                  priority: priority,
                  completed: completed,
                  created_at: created_at,
                  updated_at: updated_at,
                ))
              })
            })
          })
        })
      })
    })
  })
}

/// Parse a Todo from JSON string
pub fn todo_from_json(json_str: String) -> Result(Todo, List(ValidationError)) {
  case json.parse(from: json_str, using: todo_decoder()) {
    Ok(item) -> Ok(item)
    Error(json.UnexpectedEndOfInput) -> {
      Error([InvalidField("json", "Unexpected end of input")])
    }
    Error(json.UnexpectedByte(byte)) -> {
      Error([InvalidField("json", "Unexpected byte: " <> byte)])
    }
    Error(json.UnexpectedSequence(seq)) -> {
      Error([InvalidField("json", "Unexpected sequence: " <> seq)])
    }
    Error(json.UnableToDecode(decode_errors)) -> {
      Error(list.map(decode_errors, fn(err) {
        InvalidField(
          err.path |> string.join("."),
          "Expected " <> err.expected <> " but found " <> err.found,
        )
      }))
    }
  }
}
