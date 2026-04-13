/// Application state for todo management with empty state UI and error handling support

import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}
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
    todos: List<Todo>,
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

/// Default/initial model state
pub fn default() -> Model {
  Model(
    todos: [],
    loading: Idle,
    filter: All,
    error: None,
    form: FormState(title: "", description: "", priority: shared.Medium),
    retry_action: None,
  )
}

/// Get filtered todos based on current filter setting
pub fn get_filtered_todos(model: Model) -> List(Todo) {
  case model.filter {
    All -> model.todos
    Active -> filter_by_completed(model.todos, False)
    Completed -> filter_by_completed(model.todos, True)
  }
}

/// Filter todos by completion status
fn filter_by_completed(todos: List(Todo), completed: Bool) -> List(Todo) {
  todos
  |> list.filter(fn(todo_item) { todo_item.completed == completed })
}

/// Check if the current filtered view is empty
pub fn is_filtered_empty(model: Model) -> Bool {
  get_filtered_todos(model) |> list.is_empty
}

/// Get the appropriate empty state message based on filter
pub fn get_empty_message(model: Model) -> String {
  case model.filter {
    All -> "No todos yet. Add your first todo above!"
    Active -> "No active todos"
    Completed -> "No completed todos"
  }
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
    Some(error) -> {
      case dict.get(error.field_errors, field) {
        Ok(msg) -> msg
        Error(_) -> ""
      }
    }
    None -> ""
  }
}

/// Check if a field has an error
pub fn has_field_error(model: Model, field: String) -> Bool {
  case model.error {
    Some(error) -> dict.has_key(error.field_errors, field)
    None -> False
  }
}
