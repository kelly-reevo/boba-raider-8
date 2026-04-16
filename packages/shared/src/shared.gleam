/// Shared types and functions for boba-raider-8

import gleam/json.{type Json}
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/option.{type Option}

/// Application error types with structured error details
pub type AppError {
  NotFound
  InvalidInput(List(String))
  InternalError
  DecodeError(String)
}

/// Convert an error to a human-readable message
pub fn error_message(error: AppError) -> String {
  case error {
    NotFound -> "Not found"
    InvalidInput(errors) -> "Invalid input: " <> join_errors(errors)
    InternalError -> "Internal error"
    DecodeError(msg) -> "Decode error: " <> msg
  }
}

fn join_errors(errors: List(String)) -> String {
  case errors {
    [] -> ""
    [first] -> first
    _ -> join_errors_recursive(errors, "")
  }
}

fn join_errors_recursive(errors: List(String), acc: String) -> String {
  case errors {
    [] -> acc
    [first] -> acc <> first
    [first, ..rest] -> join_errors_recursive(rest, acc <> first <> ", ")
  }
}

/// Encode AppError to JSON error response format
pub fn error_to_json(error: AppError) -> String {
  case error {
    InvalidInput(details) -> {
      json.object([
        #("error", json.string("invalid_input")),
        #("details", json.array(details, json.string)),
      ])
      |> json.to_string
    }
    NotFound -> {
      json.object([#("error", json.string("not_found"))])
      |> json.to_string
    }
    InternalError -> {
      json.object([#("error", json.string("internal_error"))])
      |> json.to_string
    }
    DecodeError(msg) -> {
      json.object([
        #("error", json.string("decode_error")),
        #("message", json.string(msg)),
      ])
      |> json.to_string
    }
  }
}

/// Priority levels for Todo items
pub type Priority {
  High
  Medium
  Low
}

/// Todo domain type representing a task
pub type Todo {
  Todo(
    id: String,
    title: String,
    description: Option(String),
    priority: Priority,
    completed: Bool,
  )
}

/// Encode a Priority to a JSON string value
pub fn priority_encode(priority: Priority) -> Json {
  case priority {
    High -> json.string("high")
    Medium -> json.string("medium")
    Low -> json.string("low")
  }
}

/// Decoder for Priority type
pub fn priority_decoder() -> decode.Decoder(Priority) {
  use str <- decode.then(decode.string)
  case str {
    "high" -> decode.success(High)
    "medium" -> decode.success(Medium)
    "low" -> decode.success(Low)
    _ -> decode.failure(High, "Priority must be 'low', 'medium', or 'high'")
  }
}

/// Encode a Todo to JSON
pub fn todo_to_json(t: Todo) -> Json {
  json.object([
    #("id", json.string(t.id)),
    #("title", json.string(t.title)),
    #("description", case t.description {
      option.Some(desc) -> json.string(desc)
      option.None -> json.null()
    }),
    #("priority", priority_encode(t.priority)),
    #("completed", json.bool(t.completed)),
  ])
}

/// Decoder for Todo type
fn todo_decoder() -> decode.Decoder(Todo) {
  use id <- decode.field("id", decode.string)
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  use priority <- decode.field("priority", priority_decoder())
  use completed <- decode.field("completed", decode.bool)
  decode.success(Todo(id:, title:, description:, priority:, completed:))
}

/// Decode a Todo from a Dynamic value
pub fn todo_from_json(value: Dynamic) -> Result(Todo, AppError) {
  case decode.run(value, todo_decoder()) {
    Ok(t) -> Ok(t)
    Error(_) -> Error(DecodeError("Failed to decode Todo from JSON"))
  }
}
