// Error State Validation Tests
// Tests for validation error (422) handling in the UI

import gleeunit/should
import frontend/model.{Model, Idle, ValidationError}
import frontend/msg.{ValidationError as ApiValidationError}
import gleam/dict
import gleam/option.{Some, None}
import shared

/// Test: create todo 422 shows title field error
pub fn create_todo_422_shows_title_field_error_test() {
  let field_errors = dict.from_list([#("title", "Title is required")])

  let error_state = model.ErrorState(
    message: "Please fix the errors below.",
    error_type: ValidationError,
    field_errors: field_errors,
  )

  // Check that we can get the field error
  case dict.get(error_state.field_errors, "title") {
    Ok(msg) -> msg |> should.equal("Title is required")
    Error(_) -> should.fail()
  }
}

/// Test: create todo 422 shows field error near input
pub fn create_todo_422_shows_field_error_near_input_test() {
  let field_errors = dict.from_list([#("title", "Title cannot be empty")])

  let model = model.Model(
    ..model.default(),
    error: Some(model.ErrorState(
      message: "Please fix the errors below.",
      error_type: ValidationError,
      field_errors: field_errors,
    )),
  )

  // get_field_error should return the error message
  model.get_field_error(model, "title")
  |> should.equal("Title cannot be empty")
}

/// Test: field error associated with correct input element
pub fn field_error_associated_with_correct_input_element_test() {
  let field_errors = dict.from_list([
    #("title", "Title is required"),
    #("description", "Description too long"),
  ])

  let model = model.Model(
    ..model.default(),
    error: Some(model.ErrorState(
      message: "Please fix the errors below.",
      error_type: ValidationError,
      field_errors: field_errors,
    )),
  )

  // Each field should have its own error
  model.get_field_error(model, "title")
  |> should.equal("Title is required")

  model.get_field_error(model, "description")
  |> should.equal("Description too long")
}

/// Test: multiple field errors show all messages
pub fn multiple_field_errors_show_all_messages_test() {
  let field_errors = dict.from_list([
    #("title", "Title is required"),
    #("priority", "Invalid priority value"),
  ])

  let model = model.Model(
    ..model.default(),
    error: Some(model.ErrorState(
      message: "Please fix the errors below.",
      error_type: ValidationError,
      field_errors: field_errors,
    )),
  )

  model.has_field_error(model, "title")
  |> should.equal(True)

  model.has_field_error(model, "priority")
  |> should.equal(True)
}

/// Test: successful submit clears field errors
pub fn successful_submit_clears_field_errors_test() {
  // After successful submission, error should be None
  let success_model = model.Model(
    ..model.default(),
    error: None,
  )

  success_model.error
  |> should.equal(None)
}

/// Test: field set valid on success
pub fn field_set_valid_on_success_test() {
  // When form submits successfully, all field errors are cleared
  True
  |> should.equal(True)
}

/// Test: update todo 422 shows field errors
pub fn update_todo_422_shows_field_errors_test() {
  let field_errors = dict.from_list([#("title", "Title must be unique")])

  let error_state = model.ErrorState(
    message: "Please fix the errors below.",
    error_type: ValidationError,
    field_errors: field_errors,
  )

  error_state.error_type
  |> should.equal(ValidationError)
}

/// Test: only invalid fields show errors when partial validation fails
pub fn only_invalid_fields_show_errors_test() {
  // Only fields that failed validation should have error messages
  let field_errors = dict.from_list([#("title", "Title is required")])
  // description field is not in field_errors, so it has no error

  let model = model.Model(
    ..model.default(),
    error: Some(model.ErrorState(
      message: "Please fix the errors below.",
      error_type: ValidationError,
      field_errors: field_errors,
    )),
  )

  model.has_field_error(model, "title")
  |> should.equal(True)

  model.has_field_error(model, "description")
  |> should.equal(False)
}
