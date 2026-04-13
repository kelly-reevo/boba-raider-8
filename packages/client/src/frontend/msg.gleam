/// Application messages

pub type Msg {
  // Counter messages (existing)
  Increment
  Decrement
  Reset

  // API operation messages
  FetchTodos
  FetchTodosSuccess(String)
  FetchTodosError(String)

  CreateTodo
  CreateTodoSuccess(String)
  CreateTodoError(ApiError)

  UpdateTodo(String)
  UpdateTodoSuccess(String)
  UpdateTodoError(String)

  DeleteTodo(String)
  DeleteTodoSuccess(String)
  DeleteTodoError(String)

  // Error handling
  ClearError
}

/// API error type that can be general or validation
pub type ApiError {
  GeneralApiError(message: String)
  ValidationApiError(errors: List(#(String, String)))
  NetworkError
}
