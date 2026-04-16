/// Message type for user actions and API responses in the application

import frontend/model.{type FilterState}
import shared.{type Priority, type Todo}

/// HTTP error types for API operations
pub type HttpError {
  NetworkError
  DecodeError
  ServerError(Int)
  ValidationError(List(String))
}

/// Convert HttpError to display message
pub fn http_error_to_string(error: HttpError) -> String {
  case error {
    NetworkError -> "Network error. Please check your connection."
    DecodeError -> "Failed to parse server response."
    ServerError(code) -> "Server error: " <> int_to_string(code)
    ValidationError(errors) -> "Validation error: " <> join_errors(errors)
  }
}

fn join_errors(errors: List(String)) -> String {
  case errors {
    [] -> ""
    [first] -> first
    [first, ..rest] -> first <> ", " <> join_errors(rest)
  }
}

fn int_to_string(n: Int) -> String {
  case n {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    6 -> "6"
    7 -> "7"
    8 -> "8"
    9 -> "9"
    _ -> "unknown"
  }
}

/// Message type includes user actions and API response callbacks
pub type Msg {
  // Legacy counter messages (backward compatibility)
  Increment
  Decrement
  Reset
  GotCounter(Result(Int, HttpError))

  // Todo loading
  LoadTodos
  TodosLoaded(Result(List(Todo), HttpError))

  // Filter state
  SetFilter(FilterState)

  // Form field updates
  UpdateFormTitle(String)
  UpdateFormDescription(String)
  UpdateFormPriority(String)

  // Todo creation
  SubmitCreateTodo
  CreateTodoResponse(Result(Todo, HttpError))

  // Todo toggle (complete/incomplete)
  ToggleTodo(id: String, completed: Bool)
  ToggleResult(Result(Todo, HttpError))
  GotToggleResult(Result(Todo, HttpError))

  // Todo deletion (two-phase with confirmation)
  DeleteClicked(id: String)
  CancelDelete
  DeleteTodo(id: String)
  TodoDeleted(Result(String, HttpError))
}
