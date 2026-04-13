import gleeunit/should
import shared
import gleam/option.{None}

// Given a todo creation request with Low priority, when created, then priority is Low
pub fn todo_creation_with_low_priority_test() {
  let result = shared.new_todo(
    title: "Low Priority Todo",
    description: None,
    priority: shared.Low,
  )
  
  case result {
    Ok(the_todo) -> the_todo.priority |> should.equal(shared.Low)
    Error(_) -> panic as "Expected successful creation with Low priority"
  }
}
