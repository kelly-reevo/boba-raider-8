// packages/shared/test/todo_data_model_test_002.gleam
import gleam/list
import gleeunit
import gleeunit/should
import todo_data_model

pub fn main() {
  gleeunit.main()
}

pub fn empty_title_validation_error_test() {
  // Given an empty title
  let title = ""
  let description = "Some description"
  let priority = todo_data_model.Low

  // When validating (via create_todo)
  let result = todo_data_model.create_todo(title, description, priority)

  // Then validation error is returned for title field
  let errors = should.be_error(result)
  let has_title_error = errors |> list.any(fn(e) {
    e.field == "title" && e.message == "Title is required"
  })
  has_title_error |> should.equal(True)
}
