// packages/shared/test/todo_data_model_test_001.gleam
import gleeunit
import gleeunit/should
import todo_data_model

pub fn main() {
  gleeunit.main()
}

pub fn create_valid_todo_test() {
  // Given valid inputs
  let title = "Buy groceries"
  let description = "Milk, eggs, and bread"
  let priority = todo_data_model.High

  // When creating a todo
  let result = todo_data_model.create_todo(title, description, priority)

  // Then a valid todo record is produced with generated id and completed=false
  let item = should.be_ok(result)
  item.title |> should.equal(title)
  item.description |> should.equal(description)
  item.priority |> should.equal(todo_data_model.High)
  item.completed |> should.equal(False)
  // Verify id is a non-empty string (generated)
  item.id |> should.not_equal("")
}
