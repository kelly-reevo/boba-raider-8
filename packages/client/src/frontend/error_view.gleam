/// Error view functions - simplified error state rendering

import frontend/error_types.{
  type ApiError, NetworkError, NotFoundError, ServerError, ValidationError,
  network_error_props, not_found_props, server_error_props,
}
import frontend/error_boundary.{error_boundary}
import gleam/option
import lustre/element.{type Element}

/// Renders appropriate error UI based on API error type
pub fn render_api_error(
  error: ApiError,
  retry: option.Option(fn() -> Nil),
  back: option.Option(fn() -> Nil),
) -> Element(a) {
  let props = case error {
    ServerError(_) -> server_error_props(retry)
    NotFoundError(_) -> not_found_props(back)
    NetworkError(_) -> network_error_props("", retry)
    ValidationError(_) -> {
      // Validation errors are handled inline in forms, not in boundary
      error_types.ErrorBoundaryProps(
        title: "Validation Error",
        message: "Please check your input and try again.",
        retry: option.None,
        back: back,
      )
    }
  }
  error_boundary(props)
}

/// Render error for 500 server error
pub fn server_error(retry: fn() -> Nil) -> Element(a) {
  error_boundary(server_error_props(option.Some(retry)))
}

/// Render error for 404 not found
pub fn not_found(back: fn() -> Nil) -> Element(a) {
  error_boundary(not_found_props(option.Some(back)))
}

/// Render error for network/connection issues
pub fn network_error(operation: String, retry: fn() -> Nil) -> Element(a) {
  error_boundary(network_error_props(operation, option.Some(retry)))
}

/// Check if error type should show retry button
pub fn is_retryable(error: ApiError) -> Bool {
  case error {
    ServerError(_) -> True
    NetworkError(_) -> True
    NotFoundError(_) -> False
    ValidationError(_) -> False
  }
}

/// Check if error type should show back button
pub fn has_back_navigation(error: ApiError) -> Bool {
  case error {
    NotFoundError(_) -> True
    _ -> False
  }
}
