/// Message type for user actions in the application

import frontend/model

// Legacy counter app types - kept for backward compatibility with existing code
pub type HttpError {
  NetworkError
  DecodeError
  ServerError(Int)
  ValidationError(List(String))
}

/// Msg type includes both legacy counter and new todo messages
pub type Msg {
  // Legacy counter messages
  Increment
  Decrement
  Reset
  GotCounter(Result(Int, HttpError))

  // New todo messages
  AddTodo
  ToggleTodo(id: String)
  DeleteTodo(id: String)
  SetFilter(filter: model.Filter)
  UpdateInput(text: String)
}
