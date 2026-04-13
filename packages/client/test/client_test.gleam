import gleeunit
import gleeunit/should
import frontend/model
import frontend/msg
import gleam/dict
import gleam/option
import shared

pub fn main() {
  gleeunit.main()
}

/// Test that default model has empty todos and All filter
pub fn default_model_test() {
  let m = model.default()
  // Model should have empty todos list by default
  m.todos
  |> should.equal([])

  // Default filter is All
  m.filter
  |> should.equal(model.All)
}

pub fn default_model_has_no_error_test() {
  let m = model.default()
  // Model should have no error by default
  m.error
  |> should.equal(option.None)
}

/// Test empty state message for All filter
pub fn empty_message_all_filter_test() {
  let m = model.default()
  model.get_empty_message(m)
  |> should.equal("No todos yet. Add your first todo above!")
}

/// Test empty state message for Active filter
pub fn empty_message_active_filter_test() {
  let m = model.Model(..model.default(), filter: model.Active)
  model.get_empty_message(m)
  |> should.equal("No active todos")
}

/// Test empty state message for Completed filter
pub fn empty_message_completed_filter_test() {
  let m = model.Model(..model.default(), filter: model.Completed)
  model.get_empty_message(m)
  |> should.equal("No completed todos")
}

/// Test is_filtered_empty returns true when no todos
pub fn is_filtered_empty_true_test() {
  let m = model.default()
  model.is_filtered_empty(m)
  |> should.equal(True)
}

/// Test is_filtered_empty returns false when todos exist
pub fn is_filtered_empty_false_test() {
  let todo_item = shared.Todo(
    id: "1",
    title: "Test",
    description: option.None,
    priority: shared.Medium,
    completed: False,
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  )
  let m = model.Model(..model.default(), todos: [todo_item])
  model.is_filtered_empty(m)
  |> should.equal(False)
}

/// Test Active filter hides completed todos
pub fn active_filter_hides_completed_test() {
  let active_todo = shared.Todo(
    id: "1",
    title: "Active",
    description: option.None,
    priority: shared.Medium,
    completed: False,
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  )
  let completed_todo = shared.Todo(
    id: "2",
    title: "Completed",
    description: option.None,
    priority: shared.Medium,
    completed: True,
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  )
  let m = model.Model(
    ..model.default(),
    todos: [active_todo, completed_todo],
    filter: model.Active,
  )

  model.get_filtered_todos(m)
  |> should.equal([active_todo])
}

/// Test Completed filter shows only completed todos
pub fn completed_filter_shows_completed_test() {
  let active_todo = shared.Todo(
    id: "1",
    title: "Active",
    description: option.None,
    priority: shared.Medium,
    completed: False,
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  )
  let completed_todo = shared.Todo(
    id: "2",
    title: "Completed",
    description: option.None,
    priority: shared.Medium,
    completed: True,
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  )
  let m = model.Model(
    ..model.default(),
    todos: [active_todo, completed_todo],
    filter: model.Completed,
  )

  model.get_filtered_todos(m)
  |> should.equal([completed_todo])
}

/// Test All filter shows all todos
pub fn all_filter_shows_all_test() {
  let todo1 = shared.Todo(
    id: "1",
    title: "First",
    description: option.None,
    priority: shared.Medium,
    completed: False,
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  )
  let todo2 = shared.Todo(
    id: "2",
    title: "Second",
    description: option.None,
    priority: shared.Medium,
    completed: True,
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  )
  let m = model.Model(..model.default(), todos: [todo1, todo2], filter: model.All)

  model.get_filtered_todos(m)
  |> should.equal([todo1, todo2])
}

/// Test network error is retryable
pub fn network_error_is_retryable_test() {
  let error = model.ErrorState(
    message: "Network error",
    error_type: model.NetworkError,
    field_errors: dict.new(),
  )
  model.is_retryable(error)
  |> should.equal(True)
}

/// Test validation error is not retryable
pub fn validation_error_not_retryable_test() {
  let error = model.ErrorState(
    message: "Validation error",
    error_type: model.ValidationError,
    field_errors: dict.new(),
  )
  model.is_retryable(error)
  |> should.equal(False)
}

/// Test server error is not retryable
pub fn server_error_not_retryable_test() {
  let error = model.ErrorState(
    message: "Server error",
    error_type: model.GenericError,
    field_errors: dict.new(),
  )
  model.is_retryable(error)
  |> should.equal(False)
}

/// Test get_field_error returns correct field error
pub fn get_field_error_test() {
  let field_errors = dict.from_list([("title", "Title is required")])
  let error = model.ErrorState(
    message: "Validation error",
    error_type: model.ValidationError,
    field_errors: field_errors,
  )
  let m = model.Model(..model.default(), error: option.Some(error))

  model.get_field_error(m, "title")
  |> should.equal("Title is required")

  model.get_field_error(m, "description")
  |> should.equal("")
}
