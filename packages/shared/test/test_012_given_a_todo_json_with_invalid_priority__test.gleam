import gleeunit/should
import shared
import gleam/list

// Given a todo creation request with priority 'urgent', when decoded from JSON, then validation fails with error
pub fn todo_from_json_invalid_priority_fails_test() {
  let json_string = "{\"id\":\"550e8400-e29b-41d4-a716-446655440000\",\"title\":\"Test\",\"description\":null,\"priority\":\"urgent\",\"completed\":false,\"created_at\":\"2024-01-01T00:00:00Z\",\"updated_at\":\"2024-01-01T00:00:00Z\"}"

  let result = shared.todo_from_json(json_string)

  // Should return Error - 'urgent' is not a valid priority (must be low|medium|high)
  case result {
    Error(errors) -> {
      // Should have InvalidField error for priority
      let has_priority_error = list.any(errors, fn(e) {
        case e {
          shared.InvalidField("priority", _) -> True
          _ -> False
        }
      })
      should.be_true(has_priority_error)
    }
    Ok(_) -> panic as "Expected validation to fail for invalid priority 'urgent'"
  }
}

