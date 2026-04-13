// packages/shared/test/todo_data_model_test_001.gleam
import gleam/option
import gleeunit
import gleeunit/should
import shared.{High}
import todo_data_model

pub fn main() {
  gleeunit.main()
}

pub fn create_valid_todo_test() {
  // Given valid inputs
  let title = "Buy groceries"
  let description = "Milk, eggs, and bread"
  let priority = High

  // When creating a todo
  let result = todo_data_model.create_todo(title, description, priority)

  // Then a valid todo record is produced with generated id and completed=false
  let item = should.be_ok(result)
  item.title |> should.equal(title)
  // description is now Option(String), check it exists
  case item.description {
    option.Some(d) -> d |> should.equal(description)
    option.None -> should.fail()
  }
  item.priority |> should.equal("high")
  item.completed |> should.equal(False)
  // Verify id is a non-empty string (generated)
  item.id |> should.not_equal("")
}
