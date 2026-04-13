/// Shared types and functions for boba-raider-8

import gleam/json.{type Json}

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

/// Todo item type
pub type Todo {
  Todo(
    id: String,
    title: String,
    description: String,
    completed: Bool,
    priority: String,
  )
}

/// Encode a Todo to JSON
pub fn todo_to_json(item: Todo) -> Json {
  json.object([
    #("id", json.string(item.id)),
    #("title", json.string(item.title)),
    #("description", json.string(item.description)),
    #("completed", json.bool(item.completed)),
    #("priority", json.string(item.priority)),
  ])
}

/// Encode a list of Todos to JSON
pub fn todos_to_json(items: List(Todo)) -> Json {
  json.array(items, todo_to_json)
}

/// Filter type for todos
pub type Filter {
  All
  Active
  Completed
}

/// Convert filter to string
pub fn filter_to_string(filter: Filter) -> String {
  case filter {
    All -> "all"
    Active -> "active"
    Completed -> "completed"
  }
}

/// Parse filter from string
pub fn filter_from_string(str: String) -> Filter {
  case str {
    "active" -> Active
    "completed" -> Completed
    _ -> All
  }
}
