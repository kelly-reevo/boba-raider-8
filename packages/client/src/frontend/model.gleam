/// Application state with comprehensive error handling
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

/// Application model with todo state and error handling
pub type Model {
  Model(
    // Todo list state
    todos: List(Todo),
    loading: Bool,
    // Form state
    form_title: String,
    form_description: String,
    form_priority: String,
    // Error state
    form_errors: List(FieldError),
    list_error: Option(ApiError),
    global_error: Option(ApiError),
  )
}

/// Todo data type
pub type Todo {
  Todo(id: String, title: String, description: String, priority: String, completed: Bool)
}

/// Default/initial model state
pub fn default() -> Model {
  Model(
    todos: [],
    loading: False,
    form_title: "",
    form_description: "",
    form_priority: "medium",
    form_errors: [],
    list_error: None,
    global_error: None,
  )
}
