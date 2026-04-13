import gleam/int
import frontend/model.{type Model}
import frontend/msg.{type Msg}
import frontend/error_types.{
  NetworkError, NotFoundError, ServerError, ValidationError,
}
import frontend/error_boundary.{error_boundary}
import gleam/option.{Some, None}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [element.text("boba-raider-8")]),

    // Error boundary display
    render_error_state(model),

    // Loading indicator
    render_loading(model.is_loading),

    // Main content (hidden when error or loading)
    html.div([attribute.class("main-content")], [
      html.div([attribute.class("counter")], [
        html.button([event.on_click(msg.Decrement)], [element.text("-")]),
        html.span([attribute.class("count")], [
          element.text("Count: " <> int.to_string(model.count)),
        ]),
        html.button([event.on_click(msg.Increment)], [element.text("+")]),
      ]),
      html.button([event.on_click(msg.Reset), attribute.class("reset")], [
        element.text("Reset"),
      ]),
    ]),
  ])
}

/// Render error state based on current error type
fn render_error_state(model: Model) -> Element(Msg) {
  case model.error, model.is_loading {
    // Hide error when retrying
    Some(_), True -> element.none()

    // 500 Server Error - Something went wrong with retry
    Some(ServerError(_)), _ ->
      error_boundary(
        error_types.ErrorBoundaryProps(
          title: "Something went wrong",
          message: "We encountered an error processing your request. Please try again.",
          retry: Some(fn() { Nil }), // Retry callback
          back: None,
        ),
      )

    // 404 Not Found - back navigation
    Some(NotFoundError(_)), _ ->
      error_boundary(
        error_types.ErrorBoundaryProps(
          title: "Not found",
          message: "The page or resource you're looking for doesn't exist.",
          retry: None,
          back: Some(fn() { Nil }), // Back callback
        ),
      )

    // Network Error - Check your connection with retry
    Some(NetworkError(_)), _ ->
      error_boundary(
        error_types.ErrorBoundaryProps(
          title: "Connection Error",
          message: "Failed to load drinks. Check your connection and retry.",
          retry: Some(fn() { Nil }), // Retry callback
          back: None,
        ),
      )

    // Validation Error - inline errors
    Some(ValidationError(errors)), _ ->
      error_boundary.form_validation_errors(errors)

    // No error
    None, _ -> element.none()
  }
}

/// Render loading state
fn render_loading(is_loading: Bool) -> Element(Msg) {
  case is_loading {
    True ->
      html.div([attribute.class("loading-indicator")], [
        element.text("Loading..."),
      ])
    False -> element.none()
  }
}
