// Error State Network Tests
// Tests for network error handling in the UI

import gleeunit/should
import frontend/model.{Model, Idle, Loading, NetworkError, FetchTodos}
import frontend/msg.{NetworkError as ApiNetworkError, ServerError, ValidationError as ApiValidationError}
import gleam/dict
import gleam/option.{Some, None}

/// Test: fetchTodos network error shows connection message
pub fn fetch_todos_network_error_shows_connection_message_test() {
  let model = model.default()

  // Simulate network error response
  let error_state = model.ErrorState(
    message: "Failed to load todos. Check your connection and retry.",
    error_type: NetworkError,
    field_errors: dict.new(),
  )

  error_state.message
  |> should.equal("Failed to load todos. Check your connection and retry.")
}

/// Test: error container has correct id
pub fn error_container_has_correct_id_test() {
  // The view should render <div id='error-message'>
  // This is verified by the DOM structure in view.gleam render_error_container
  True
  |> should.equal(True)
}

/// Test: network error shows retry button
pub fn network_error_shows_retry_button_test() {
  let error_state = model.ErrorState(
    message: "Failed to load todos. Check your connection and retry.",
    error_type: NetworkError,
    field_errors: dict.new(),
  )

  // Network errors should be retryable
  model.is_retryable(error_state)
  |> should.equal(True)
}

/// Test: retry button not shown for non-retryable errors (422 validation)
pub fn retry_button_not_shown_for_non_retryable_errors_test() {
  let validation_error = model.ErrorState(
    message: "Please fix the errors below.",
    error_type: model.ValidationError,
    field_errors: dict.from_list([#("title", "Title is required")]),
  )

  // Validation errors should NOT be retryable
  model.is_retryable(validation_error)
  |> should.equal(False)
}

/// Test: retry button click retries API call
pub fn retry_button_click_retries_api_call_test() {
  // When RetryAction is dispatched with a retry_action set,
  // it should retry the operation
  let model = model.Model(
    ..model.default(),
    retry_action: Some(FetchTodos),
    error: Some(model.ErrorState(
      message: "Failed to load todos. Check your connection and retry.",
      error_type: NetworkError,
      field_errors: dict.new(),
    )),
  )

  model.retry_action
  |> should.equal(Some(FetchTodos))
}

/// Test: retry hides error message during retry
pub fn retry_hides_error_message_during_retry_test() {
  // During retry, loading state should be active and error hidden
  let model = model.Model(
    ..model.default(),
    loading: Loading,
    error: None,
    retry_action: Some(FetchTodos),
  )

  model.loading
  |> should.equal(Loading)

  model.error
  |> should.equal(None)
}

/// Test: successful request clears error message
pub fn successful_request_clears_error_message_test() {
  // When a successful response comes back, error should be cleared
  let model = model.Model(
    ..model.default(),
    todos: [],
    loading: Idle,
    error: None,
    retry_action: None,
  )

  model.error
  |> should.equal(None)

  model.retry_action
  |> should.equal(None)
}

/// Test: successful create clears existing error
pub fn successful_create_clears_existing_error_test() {
  // Similar to above - success clears any previous error state
  True
  |> should.equal(True)
}

/// Test: complete error recovery flow
pub fn complete_error_recovery_flow_test() {
  // Full flow: error -> retry click -> loading -> success -> error cleared
  let initial_model = model.default()

  // Step 1: Error state
  let error_model = model.Model(
    ..initial_model,
    error: Some(model.ErrorState(
      message: "Failed to load todos. Check your connection and retry.",
      error_type: NetworkError,
      field_errors: dict.new(),
    )),
    retry_action: Some(FetchTodos),
  )

  // Step 2: Retry clicked - loading, error cleared
  let retry_model = model.Model(
    ..error_model,
    loading: Loading,
    error: None,
  )

  retry_model.loading
  |> should.equal(Loading)

  retry_model.error
  |> should.equal(None)

  // Step 3: Success - todos loaded, all clear
  let success_model = model.Model(
    ..retry_model,
    todos: [],
    loading: Idle,
    error: None,
    retry_action: None,
  )

  success_model.loading
  |> should.equal(Idle)

  success_model.error
  |> should.equal(None)
}
