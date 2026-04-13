/// Application messages for Todo App with error handling

import frontend/model.{type Todo}

/// Main message type
pub type Msg {
  // Form input handling
  FormInputChanged(String)
  FormSubmitted

  // Todo operations - requests
  LoadTodosRequest
  AddTodoRequest
  UpdateTodoRequest(id: String, completed: Bool)
  DeleteTodoRequest(id: String)

  // Todo operations - success responses
  LoadTodosSuccess(todos: List(Todo))
  AddTodoSuccess(item: Todo)
  UpdateTodoSuccess(item: Todo)
  DeleteTodoSuccess(id: String)

  // Todo operations - error responses
  LoadTodosError(error: String)
  AddTodoError(error: String)
  UpdateTodoError(id: String, original_completed: Bool, error: String)
  DeleteTodoError(id: String, item: Todo, error: String)

  // Error management
  ClearTransientError
  DismissError(container: ErrorContainer)
}

/// Error container types for targeted dismissal
pub type ErrorContainer {
  ListErrorContainer
  FormErrorContainer
  GlobalErrorContainer
}
