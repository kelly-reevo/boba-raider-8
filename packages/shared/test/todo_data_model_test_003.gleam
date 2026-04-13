// packages/shared/test/todo_data_model_test_003.gleam
import gleam/list
import gleeunit
import gleeunit/should
import shared.{ValidationError}
import todo_data_model

pub fn main() {
  gleeunit.main()
}

pub fn invalid_priority_validation_error_test() {
  // Given an invalid priority string
  let invalid_priority = "urgent"

  // When validating priority
  let result = todo_data_model.validate_priority(invalid_priority)

  // Then validation error is returned for priority field
  let errors = should.be_error(result)
  let has_priority_error = errors |> list.any(fn(e) {
    e.field == "priority" && e.message == "Invalid priority value"
  })
  has_priority_error |> should.equal(True)
}
