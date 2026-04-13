/// Shared types and functions for boba-raider-8

/// Todo item type
pub type TodoItem {
  TodoItem(id: String, title: String, completed: Bool)
}

/// Application errors
pub type AppError {
  NotFound(String)
  InvalidInput(String)
  InternalError(String)
  NetworkError(String)
}

/// Convert an error to a human-readable message
pub fn error_message(error: AppError) -> String {
  case error {
    NotFound(msg) -> "Not found: " <> msg
    InvalidInput(msg) -> "Invalid input: " <> msg
    InternalError(msg) -> "Internal error: " <> msg
    NetworkError(msg) -> msg
  }
}

/// Convert TodoItem to JSON
pub fn todo_to_json(item: TodoItem) -> String {
  "{\"id\":\"" <> item.id <> "\",\"title\":\"" <> item.title <> "\",\"completed\":" <> case item.completed {
    True -> "true"
    False -> "false"
  } <> "}"
}
