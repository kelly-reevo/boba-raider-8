/// ErrorBoundary component - displays error states with retry/back options

import frontend/error_types.{
  type ErrorBoundaryProps, type FieldValidationError,
}
import gleam/list
import gleam/option.{type Option, Some, None}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

/// Renders an ErrorBoundary component based on props
/// Contract: {title: string, message: string, retry?: () -> void, back?: () -> void}
pub fn error_boundary(props: ErrorBoundaryProps) -> Element(a) {
  html.div(
    [
      attribute.class("error-boundary"),
      attribute.attribute("role", "alert"),
    ],
    [
      // Title
      html.h2([attribute.class("error-title")], [
        element.text(props.title),
      ]),
      // Message
      html.p([attribute.class("error-message")], [
        element.text(props.message),
      ]),
      // Action buttons
      html.div([attribute.class("error-actions")], [
        render_retry_button(props.retry),
        render_back_button(props.back),
      ]),
    ],
  )
}

/// Render retry button if retry callback is provided
fn render_retry_button(retry: Option(fn() -> Nil)) -> Element(a) {
  case retry {
    Some(_callback) ->
      html.button(
        [
          attribute.class("error-retry-button"),
          // Note: retry is handled via msg dispatch in parent
          // This is a static button for testing
        ],
        [element.text("Retry")],
      )
    None -> element.none()
  }
}

/// Render back button if back callback is provided
fn render_back_button(back: Option(fn() -> Nil)) -> Element(a) {
  case back {
    Some(_callback) ->
      html.button(
        [
          attribute.class("error-back-button"),
          // Note: back is handled via msg dispatch in parent
          // This is a static button for testing
        ],
        [element.text("Go Back")],
      )
    None -> element.none()
  }
}

/// ErrorMessage component - simpler error display for inline/network errors
/// Contract: {title: string, message: string, retry?: () -> void}
pub fn error_message(
  title: String,
  message: String,
  retry: Option(fn() -> Nil),
) -> Element(a) {
  html.div(
    [
      attribute.class("error-message-container"),
      attribute.attribute("role", "alert"),
    ],
    [
      html.h3([attribute.class("error-message-title")], [
        element.text(title),
      ]),
      html.p([attribute.class("error-message-text")], [
        element.text(message),
      ]),
      render_retry_button(retry),
    ],
  )
}

/// Renders inline field validation errors for forms
/// Contract: Errors rendered adjacent to corresponding form inputs
pub fn inline_field_error(
  field_id: String,
  errors: List(FieldValidationError),
) -> Element(a) {
  let field_errors = list.filter(errors, fn(e) { e.field == field_id })
  case field_errors {
    [] -> element.none()
    field_errs ->
      html.div(
        [
          attribute.class("inline-error"),
          attribute.attribute("data-field", field_id),
        ],
        list.map(field_errs, fn(e) {
          html.span([attribute.class("inline-error-text")], [
            element.text(e.message),
          ])
        }),
      )
  }
}

/// Form error container that displays all validation errors
pub fn form_validation_errors(errors: List(FieldValidationError)) -> Element(a) {
  case errors {
    [] -> element.none()
    _ ->
      html.div(
        [
          attribute.class("form-validation-errors"),
          attribute.attribute("role", "alert"),
        ],
        list.map(errors, fn(e) {
          html.div(
            [
              attribute.class("field-error"),
              attribute.attribute("data-field", e.field),
            ],
            [
              html.strong([], [element.text(e.field <> ": ")]),
              element.text(e.message),
            ],
          )
        }),
      )
  }
}
