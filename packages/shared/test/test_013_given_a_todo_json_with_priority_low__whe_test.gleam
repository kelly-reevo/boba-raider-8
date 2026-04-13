import gleeunit/should
import shared

// Given a JSON with priority 'low', when decoded, then priority is set to Low
pub fn todo_from_json_low_priority_test() {
  let json_string = "{\"id\":\"550e8400-e29b-41d4-a716-446655440000\",\"title\":\"Test\",\"description\":null,\"priority\":\"low\",\"completed\":false,\"created_at\":\"2024-01-01T00:00:00Z\",\"updated_at\":\"2024-01-01T00:00:00Z\"}"
  
  let result = shared.todo_from_json(json_string)
  
  case result {
    Ok(the_todo) -> the_todo.priority |> should.equal(shared.Low)
    Error(_) -> panic as "Expected successful decode for 'low' priority"
  }
}
