/// Error state types for API failure handling

import gleam/option.{type Option}

/// Represents different types of API errors
pub type ApiError {
  /// 500, 502, 503 server errors - shows "Something went wrong" with retry
  ServerError(message: String)
  /// 404 not found - shows "Not found" with back navigation
  NotFoundError(message: String)
  /// Network/connection errors - shows "Check your connection" with retry
  NetworkError(message: String)
  /// 422 validation errors - shows inline field errors
  ValidationError(field_errors: List(FieldValidationError))
}

/// Single field validation error from API 422 response
pub type FieldValidationError {
  FieldValidationError(field: String, message: String)
}

/// Props for ErrorBoundary component
/// Contract: {title: string, message: string, retry?: () -> void, back?: () -> void}
pub type ErrorBoundaryProps {
  ErrorBoundaryProps(
    title: String,
    message: String,
    retry: Option(fn() -> Nil),
    back: Option(fn() -> Nil),
  )
}

/// Props for ErrorMessage component (simpler, just message display)
pub type ErrorMessageProps {
  ErrorMessageProps(
    title: String,
    message: String,
    retry: Option(fn() -> Nil),
  )
}

/// Creates props for a 500 server error
pub fn server_error_props(retry: Option(fn() -> Nil)) -> ErrorBoundaryProps {
  ErrorBoundaryProps(
    title: "Something went wrong",
    message: "We encountered an error processing your request. Please try again.",
    retry: retry,
    back: option.None,
  )
}

/// Creates props for a 404 not found error
pub fn not_found_props(back: Option(fn() -> Nil)) -> ErrorBoundaryProps {
  ErrorBoundaryProps(
    title: "Not found",
    message: "The page or resource you're looking for doesn't exist.",
    retry: option.None,
    back: back,
  )
}

/// Creates props for a network error
pub fn network_error_props(
  operation: String,
  retry: Option(fn() -> Nil),
) -> ErrorBoundaryProps {
  let message = case operation {
    "load drinks" -> "Failed to load drinks. Check your connection and retry."
    "submit rating" -> "Failed to submit rating. Check your connection and retry."
    "load stores" -> "Failed to load stores. Check your connection and retry."
    _ -> "Failed to complete request. Check your connection and retry."
  }
  ErrorBoundaryProps(
    title: "Connection Error",
    message: message,
    retry: retry,
    back: option.None,
  )
}

/// Convert ApiError to ErrorBoundaryProps
pub fn api_error_to_props(
  error: ApiError,
  retry: Option(fn() -> Nil),
  back: Option(fn() -> Nil),
) -> ErrorBoundaryProps {
  case error {
    ServerError(msg) -> ErrorBoundaryProps(
      title: "Something went wrong",
      message: msg,
      retry: retry,
      back: option.None,
    )
    NotFoundError(msg) -> ErrorBoundaryProps(
      title: "Not found",
      message: msg,
      retry: option.None,
      back: back,
    )
    NetworkError(msg) -> ErrorBoundaryProps(
      title: "Connection Error",
      message: msg,
      retry: retry,
      back: option.None,
    )
    ValidationError(_) -> ErrorBoundaryProps(
      title: "Validation Error",
      message: "Please check your input and try again.",
      retry: option.None,
      back: back,
    )
  }
}
