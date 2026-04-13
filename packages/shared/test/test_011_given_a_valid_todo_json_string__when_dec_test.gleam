import gleeunit/should
import shared

// Given a valid Todo JSON string, when decoded via todo_from_json, then returns Ok with correct fields
pub fn todo_from_json_valid_input_test() {
  let json_string = "{\"id\":\"550e8400-e29b-41d4-a716-446655440000\",\"title\":\"Test\",\"description\":\"Desc\",\"priority\":\"medium\",\"completed\":false,\"created_at\":\"2024-01-01T00:00:00Z\",\"updated_at\":\"2024-01-01T00:00:00Z\"}"
  
  let result = shared.todo_from_json(json_string)
  
  case result {
    Ok(the_todo) -> {
      the_todo.id |> should.equal("550e8400-e29b-41d4-a716-446655440000")
      the_todo.title |> should.equal("Test")
      the_todo.priority |> should.equal(shared.Medium)
      the_todo.completed |> should.equal(False)
    }
    Error(errors) -> panic
  }
}



fn inspect(value: a) -> String {
  "inspect"
}