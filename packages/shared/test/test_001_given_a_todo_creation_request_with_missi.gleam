import gleeunit
import gleeunit/should
import shared
import gleam/list
import gleam/option.{Some, None}

pub fn main() {
  gleeunit.main()
}

// Test: Empty string title returns validation error
pub fn todo_creation_empty_title_returns_validation_error_test() {
  let result = shared.new_todo(
    title: "",
    description: Some("Valid description"),
    priority: shared.Medium,
  )

  result |> should.be_error()
}

// Test: Whitespace-only title returns validation error (trimmed to empty)
pub fn todo_creation_whitespace_title_returns_validation_error_test() {
  let result = shared.new_todo(
    title: "   ",
    description: Some("Valid description"),
    priority: shared.Medium,
  )

  result |> should.be_error()
}

// Test: Validation error contains MissingField for title
pub fn todo_creation_error_contains_title_missing_field_test() {
  let result = shared.new_todo(
    title: "",
    description: None,
    priority: shared.Low,
  )

  case result {
    Error(errors) -> {
      let has_title_error = list.any(errors, fn(e) {
        case e {
          shared.MissingField("title") -> True
          shared.InvalidField("title", _) -> True
          _ -> False
        }
      })
      has_title_error |> should.equal(True)
    }
    Ok(_) -> should.fail()
  }
}

// Test: Error response is list of ValidationError objects
pub fn todo_validation_error_returns_list_of_validation_errors_test() {
  let result = shared.new_todo(
    title: "",
    description: None,
    priority: shared.Medium,
  )

  case result {
    Error(errors) -> {
      // Errors is a non-empty list
      { list.length(errors) > 0 } |> should.equal(True)
    }
    Ok(_) -> should.fail()
  }
}
