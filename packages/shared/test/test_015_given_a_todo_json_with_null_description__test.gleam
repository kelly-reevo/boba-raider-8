import gleeunit/should
import shared
import gleam/option.{None}

// Given a JSON with null description, when decoded, then description is None
pub fn todo_from_json_null_description_test() {
  let json_string = "{\"id\":\"550e8400-e29b-41d4-a716-446655440000\",\"title\":\"Test\",\"description\":null,\"priority\":\"medium\",\"completed\":false,\"created_at\":\"2024-01-01T00:00:00Z\",\"updated_at\":\"2024-01-01T00:00:00Z\"}"
  
  let result = shared.todo_from_json(json_string)
  
  case result {
    Ok(the_todo) -> the_todo.description |> should.equal(None)
    Error(_) -> panic as "Expected successful decode for null description"
  }
}
