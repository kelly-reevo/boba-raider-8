/// Application state with comprehensive error handling AND filter support
import gleam/option.{type Option, None}

/// Error state for field-level validation errors (422 responses)
pub type FieldError {
  FieldError(field: String, message: String)
}

/// Container type for error display location
pub type ErrorContainer {
  FormError
  ListError
  GlobalError
}

/// API error types matching backend responses
pub type ApiError {
  ValidationError(errors: List(FieldError))
  NotFoundError(message: String)
  ServerError(message: String)
  NetworkError(message: String)
}

/// Filter type for todo status filtering
pub type Filter {
  All
  Active
  Completed
}

/// Todo data type
pub type Todo {
  Todo(id: String, title: String, description: String, priority: String, completed: Bool)
}

/// Application model with todo state, error handling, AND filtering
pub type Model {
  Model(
    // Todo list state
    todos: List(Todo),
    loading: Bool,
    current_filter: Filter,
    // Form state
    form_title: String,
    form_description: String,
    form_priority: String,
    // Error state
    form_errors: List(FieldError),
    list_error: Option(ApiError),
    global_error: Option(ApiError),
    // Legacy counter (keep for compatibility)
    count: Int,
  )
}

/// Default/initial model state
pub fn default() -> Model {
  Model(
    todos: [],
    loading: False,
    current_filter: All,
    form_title: "",
    form_description: "",
    form_priority: "medium",
    form_errors: [],
    list_error: None,
    global_error: None,
    count: 0,
  )
}
