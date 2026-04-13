/// Shared types and functions for boba-raider-8

import gleam/json.{type Json}

/// Todo data model representing a task
pub type Todo {
  Todo(
    id: String,
    title: String,
    description: String,
    priority: String,
    completed: Bool,
    created_at: String,
  )
}

/// Encode a Todo to JSON
pub fn todo_to_json(t: Todo) -> Json {
  json.object([
    #("id", json.string(t.id)),
    #("title", json.string(t.title)),
    #("description", json.string(t.description)),
    #("priority", json.string(t.priority)),
    #("completed", json.bool(t.completed)),
    #("created_at", json.string(t.created_at)),
  ])
}

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
