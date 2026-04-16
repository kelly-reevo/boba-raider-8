import gleeunit/should
import shared/todo_validation
import gleam/option.{None}

pub fn invalid_priority_returns_error_test() {
  let result = todo_validation.validate("Valid Title", None, "urgent")
  
  result
  |> should.be_error()
  |> should.equal(["invalid priority"])
}
