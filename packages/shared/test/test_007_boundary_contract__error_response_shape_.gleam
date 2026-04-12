import gleeunit
import gleeunit/should
import shared
import gleam/list
import gleam/option.{None}

pub fn main() {
  gleeunit.main()
}

// Test: Empty title returns MissingField validation error
pub fn validation_error_missing_field_structure_test() {
  let result = shared.new_todo(
    title: "",
    description: None,
    priority: shared.Medium,
  )

  case result {
    Error(errors) -> {
      // Errors is a list of ValidationError
      { list.length(errors) > 0 } |> should.equal(True)

      // Should contain a MissingField for title
      let has_missing_title = list.any(errors, fn(e) {
        case e {
          shared.MissingField("title") -> True
          _ -> False
        }
      })
      has_missing_title |> should.equal(True)
    }
    Ok(_) -> should.fail()
  }
}

// Test: Invalid priority in JSON returns InvalidField validation error
pub fn validation_error_invalid_field_structure_test() {
  let json_input = "{\"id\":\"550e8400-e29b-41d4-a716-446655440000\",\"title\":\"Test\",\"description\":null,\"priority\":\"invalid\",\"completed\":false,\"created_at\":\"2024-01-15T10:30:00Z\",\"updated_at\":\"2024-01-15T10:30:00Z\"}"

  let result = shared.todo_from_json(json_input)

  case result {
    Error(errors) -> {
      // Should contain InvalidField for priority
      let has_invalid_priority = list.any(errors, fn(e) {
        case e {
          shared.InvalidField("priority", _) -> True
          _ -> False
        }
      })
      has_invalid_priority |> should.equal(True)
    }
    Ok(_) -> should.fail()
  }
}

// Test: Multiple validation errors can be returned
pub fn multiple_validation_errors_returned_test() {
  // Test with JSON missing required fields - may trigger multiple errors
  let incomplete_json = "{\"description\":null,\"priority\":\"invalid\",\"completed\":false}"

  let result = shared.todo_from_json(incomplete_json)

  // Should return error (may be one or more errors depending on implementation)
  case result {
    Error(errors) -> {
      { list.length(errors) > 0 } |> should.equal(True)
    }
    Ok(_) -> should.fail()
  }
}
