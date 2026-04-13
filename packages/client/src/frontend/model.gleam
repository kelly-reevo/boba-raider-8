/// Application state

import gleam/dict.{type Dict}
import gleam/option.{type Option}
import shared.{type Todo, type Priority}

/// Type of error for determining UI behavior
pub type ErrorType {
  NetworkError
  ValidationError
  GenericError
}

/// Error state for the application
pub type ErrorState {
  ErrorState(
    message: String,
    error_type: ErrorType,
    /// For 422 validation errors: field -> error message
    field_errors: Dict(String, String),
  )
}

/// Loading states for async operations
pub type LoadingState {
  Idle
  Loading
  Saving
  Deleting
}

/// Filter for todo list
pub type Filter {
  All
  Active
  Completed
}

/// Form state for creating/editing todos
pub type FormState {
  FormState(
    title: String,
    description: String,
    priority: Priority,
  )
}

pub type Model {
  Model(
    /// List of todos
    todos: List(Todo),
    /// Current loading state
    loading: LoadingState,
    /// Current filter for todo list
    filter: Filter,
    /// Global error state (for network/server errors)
    error: Option(ErrorState),
    /// Form state for creating new todos
    form: FormState,
    /// Retry action identifier for retryable errors
    retry_action: Option(RetryAction),
  )
}

/// Actions that can be retried
pub type RetryAction {
  FetchTodos
  CreateTodo(title: String, description: Option(String), priority: Priority)
  UpdateTodo(id: String, title: String, description: Option(String), completed: Bool)
  DeleteTodo(id: String)
}

pub fn default() -> Model {
  Model(
    todos: [],
    loading: Idle,
    filter: All,
    error: option.None,
    form: FormState(title: "", description: "", priority: shared.Medium),
    retry_action: option.None,
  )
}

/// Create a network error state with retry capability
pub fn network_error(message: String, _retry: RetryAction) -> ErrorState {
  ErrorState(
    message: message,
    error_type: NetworkError,
    field_errors: dict.new(),
  )
}

/// Create a validation error state with field-specific errors
pub fn validation_error(field_errors: Dict(String, String)) -> ErrorState {
  ErrorState(
    message: "Please fix the errors below.",
    error_type: ValidationError,
    field_errors: field_errors,
  )
}

/// Create a generic error state
pub fn generic_error(message: String) -> ErrorState {
  ErrorState(
    message: message,
    error_type: GenericError,
    field_errors: dict.new(),
  )
}

/// Check if error is retryable (has NetworkError type)
pub fn is_retryable(error: ErrorState) -> Bool {
  case error.error_type {
    NetworkError -> True
    _ -> False
  }
}

/// Get error message for a specific field
pub fn get_field_error(model: Model, field: String) -> String {
  case model.error {
    option.Some(error) -> {
      case dict.get(error.field_errors, field) {
        Ok(msg) -> msg
        Error(_) -> ""
      }
    }
    option.None -> ""
  }
}

/// Check if a field has an error
pub fn has_field_error(model: Model, field: String) -> Bool {
  case model.error {
    option.Some(error) -> dict.has_key(error.field_errors, field)
    option.None -> False
  }
}
