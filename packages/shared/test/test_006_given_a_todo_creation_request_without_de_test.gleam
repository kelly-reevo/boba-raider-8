import gleeunit/should
import shared
import gleam/option.{None}

// Given a todo creation request without description, when created, then description is None
pub fn todo_creation_without_description_defaults_to_none_test() {
  let result = shared.new_todo(
    title: "Todo Without Description",
    description: None,
    priority: shared.Medium,
  )
  
  case result {
    Ok(the_todo) -> the_todo.description |> should.equal(None)
    Error(_) -> panic as "Expected successful creation without description"
  }
}
