import gleeunit/should
import shared
import gleam/option.{Some}

// Given a todo creation request with title 'Buy milk', when validated, then validation passes with no errors
pub fn todo_creation_with_valid_title_passes_validation_test() {
  let result = shared.new_todo(
    title: "Buy milk",
    description: Some("Get from store"),
    priority: shared.Medium,
  )
  
  // Should return Ok with a Todo, not an error
  case result {
    Ok(the_todo) -> {
      the_todo.title |> should.equal("Buy milk")
      the_todo.priority |> should.equal(shared.Medium)
    }
    Error(_) -> panic as "Expected validation to pass for valid title"
  }
}
