import gleeunit/should
import shared
import gleam/option.{Some}

// Given a todo creation request with description, when created, then description is correctly set
pub fn todo_creation_with_description_test() {
  let result = shared.new_todo(
    title: "Todo With Description",
    description: Some("This is the description"),
    priority: shared.Medium,
  )
  
  case result {
    Ok(the_todo) -> the_todo.description |> should.equal(Some("This is the description"))
    Error(_) -> panic as "Expected successful creation with description"
  }
}
