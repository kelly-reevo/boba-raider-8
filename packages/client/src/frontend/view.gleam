import gleam/int
import frontend/model.{type Model, type ErrorState, type ValidationError, NoError, GeneralErrorState, ValidationErrorState}
import frontend/msg.{type Msg}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    // Error container at top of app - must be first child
    error_container_view(model.error),

    // Main application content
    html.h1([], [element.text("boba-raider-8")]),
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
  ])
}

/// Renders the error container based on current error state
fn error_container_view(error_state: ErrorState) -> Element(Msg) {
  case error_state {
    NoError -> {
      html.div(
        [attribute.class("error-message")],
        [],
      )
    }
    GeneralErrorState(message) -> {
      html.div(
        [
          attribute.class("error-message"),
          attribute.class("visible"),
        ],
        [element.text(message)],
      )
    }
    ValidationErrorState(_errors) -> {
      // For validation errors, we show a summary in the main error container
      // and field-specific errors are handled separately
      html.div(
        [
          attribute.class("error-message"),
          attribute.class("visible"),
        ],
        [element.text("Please fix the errors above")],
      )
    }
  }
}

/// Helper function to get error message for a specific field
/// Returns the error message if the field has a validation error, empty string otherwise
pub fn get_field_error(error_state: ErrorState, field_name: String) -> String {
  case error_state {
    ValidationErrorState(errors) -> find_field_error(errors, field_name)
    _ -> ""
  }
}

fn find_field_error(errors: List(ValidationError), field_name: String) -> String {
  case errors {
    [] -> ""
    [first_error, ..rest] -> {
      case first_error.field == field_name {
        True -> first_error.message
        False -> find_field_error(rest, field_name)
      }
    }
  }
}

/// View for field-specific error elements
/// Creates a span element for field errors that can be used in forms
pub fn field_error_view(field_name: String, error_state: ErrorState) -> Element(Msg) {
  let error_message = get_field_error(error_state, field_name)
  let has_error = error_message != ""

  case has_error {
    True -> {
      html.span(
        [
          attribute.class("field-error"),
          attribute.attribute("data-field", field_name),
          attribute.class("visible"),
        ],
        [element.text(error_message)],
      )
    }
    False -> {
      html.span(
        [
          attribute.class("field-error"),
          attribute.attribute("data-field", field_name),
        ],
        [],
      )
    }
  }
}
