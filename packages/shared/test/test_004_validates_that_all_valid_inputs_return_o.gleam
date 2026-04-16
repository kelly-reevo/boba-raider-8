import gleeunit/should
import shared/todo_validation
import gleam/option.{Some}

pub fn valid_inputs_return_ok_test() {
  let result = todo_validation.validate("Buy groceries", Some("Milk and eggs"), "high")
  
  result
  |> should.be_ok()
  |> fn(validated) {
    validated.title |> should.equal("Buy groceries")
    validated.description |> should.equal(Some("Milk and eggs"))
    validated.priority |> should.equal("high")
  }
}
