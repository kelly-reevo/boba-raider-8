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

/// Priority levels for todos
pub type Priority {
  Low
  Medium
  High
}

/// Todo status
pub type Status {
  Pending
  InProgress
  Completed
}

/// Todo data model
pub type Todo {
  Todo(
    id: String,
    title: String,
    description: Option(String),
    priority: Priority,
    status: Status,
    created_at: String,
    updated_at: Option(String),
  )
}

/// Attributes for creating a new todo (no id/timestamps yet)
pub type TodoAttrs {
  TodoAttrs(
    title: String,
    description: Option(String),
    priority: Priority,
  )
}

/// Create todo attributes (used for create/update operations)
pub fn new_todo(
  title title: String,
  description description: Option(String),
  priority priority: Priority,
) -> TodoAttrs {
  TodoAttrs(
    title: title,
    description: description,
    priority: priority,
  )
}
