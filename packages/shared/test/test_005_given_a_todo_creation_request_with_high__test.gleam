import gleeunit/should
import shared
import gleam/option.{None}

// Given a todo creation request with High priority, when created, then priority is High
pub fn todo_creation_with_high_priority_test() {
  let result = shared.new_todo(
    title: "High Priority Todo",
    description: None,
    priority: shared.High,
  )
  
  case result {
    Ok(the_todo) -> the_todo.priority |> should.equal(shared.High)
    Error(_) -> panic as "Expected successful creation with High priority"
  }
}
