/// Todo-specific message types for extensible event handling

import frontend/todo_model.{type Todo}

/// HTTP error types for todo operations
pub type TodoHttpError {
  TodoNetworkError
  TodoDecodeError
  TodoServerError(Int)
}

/// Messages for todo operations
pub type TodoMsg {
  /// User clicked checkbox to toggle todo completion
  ToggleTodo(id: String)

  /// Toggle operation completed successfully
  TodoToggled(Result(ToggleResult, TodoHttpError))

  /// Filter selection changed
  SetFilter(filter: todo_model.Filter)

  /// Todos list loaded from server
  GotTodos(Result(List(Todo), TodoHttpError))

  /// Delete todo requested
  DeleteTodo(id: String)

  /// Delete operation completed
  TodoDeleted(Result(String, TodoHttpError))

  /// Error dismissed
  ClearError
}

/// Result of a toggle operation
pub type ToggleResult {
  ToggleResult(
    id: String,
    completed: Bool,
    todos: List(Todo),
    active_count: Int,
  )
}
