/// Shared types and functions for boba-raider-8

import gleam/option.{type Option}

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

/// Todo data model
pub type Todo {
  Todo(
    id: String,
    title: String,
    description: String,
    completed: Bool,
    created_at: Int,
    updated_at: Int,
  )
}

/// Input for updating a todo - fields are optional
pub type UpdateTodoInput {
  UpdateTodoInput(
    title: Option(String),
    description: Option(String),
    completed: Option(Bool),
  )
}

