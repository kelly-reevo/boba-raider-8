import gleeunit/should
import shared

// Given a JSON with missing title field, when decoded, then returns Error
pub fn todo_from_json_missing_title_fails_test() {
  // JSON without title field
  let json_string = "{\"id\":\"550e8400-e29b-41d4-a716-446655440000\",\"description\":null,\"priority\":\"medium\",\"completed\":false,\"created_at\":\"2024-01-01T00:00:00Z\",\"updated_at\":\"2024-01-01T00:00:00Z\"}"
  
  let result = shared.todo_from_json(json_string)
  
  // Should return Error due to missing required field
  case result {
    Error(_) -> Nil  // Expected - missing field should cause error
    Ok(_) -> panic as "Expected decode to fail for missing title field"
  }
}
