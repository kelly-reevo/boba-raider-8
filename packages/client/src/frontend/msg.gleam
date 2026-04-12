/// Application messages for todo app with loading states

import shared.{type Todo}

/// Loading state for a specific operation
pub type OperationLoading {
  ListLoading
  CreateLoading
  UpdateLoading(todo_id: String)
  DeleteLoading(todo_id: String)
}

/// User-initiated actions and system responses
pub type Msg {
  // Form messages
  UpdateTitle(String)
  UpdateDescription(String)
  SubmitForm
  ClearForm

  // Todo list operations
  LoadTodos
  TodosLoaded(List(Todo))
  LoadTodosFailed(String)

  // Create operations
  CreateTodo
  TodoCreated(Todo)
  CreateTodoFailed(String)

  // Update operations
  ToggleTodo(String, Bool)
  TodoUpdated(Todo)
  UpdateTodoFailed(String, Bool, String)

  // Delete operations
  DeleteTodo(String)
  TodoDeleted(String)
  DeleteTodoFailed(String, String)

  // Loading state management (internal)
  StartLoading(OperationLoading)
  StopLoading(OperationLoading)
  ClearError
}
