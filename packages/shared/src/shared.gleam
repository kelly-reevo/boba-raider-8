/// Shared types and functions for boba-raider-8

import gleam/option.{type Option}

/// AppError moved to shared module for reuse
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

/// Re-export Todo type from todo_data_model
pub type Todo {
  Todo(
    id: String,
    title: String,
    description: Option(String),
    priority: String,
    completed: Bool,
    created_at: Int,
    updated_at: Int,
  )
}

/// Re-export Priority type and variants
pub type Priority {
  Low
  Medium
  High
}

/// Input for updating a todo - fields are optional
pub type UpdateTodoInput {
  UpdateTodoInput(
    title: Option(String),
    description: Option(String),
    completed: Option(Bool),
  )
}

/// Validation error structure
pub type ValidationError {
  ValidationError(field: String, message: String)
}
