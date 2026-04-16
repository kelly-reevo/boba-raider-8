import gleeunit/should
import shared/todo_validation
import gleam/option.{Some}
import gleam/string

pub fn description_too_long_returns_error_test() {
  let long_description = string.repeat("b", 1001)
  let result = todo_validation.validate("Valid Title", Some(long_description), "medium")
  
  result
  |> should.be_error()
  |> should.equal(["description too long"])
}
