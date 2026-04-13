import gleeunit/should
import shared
import gleam/option.{None}

// Given a todo creation request without priority specified (using Medium), when created, then priority is Medium
pub fn todo_creation_with_explicit_medium_priority_test() {
  let result = shared.new_todo(
    title: "Test Todo",
    description: None,
    priority: shared.Medium,
  )
  
  case result {
    Ok(the_todo) -> the_todo.priority |> should.equal(shared.Medium)
    Error(_) -> panic as "Expected successful creation with Medium priority"
  }
}
