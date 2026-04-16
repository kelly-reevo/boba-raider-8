import gleeunit/should
import shared/todo_validation
import gleam/option.{None}

pub fn empty_title_returns_error_test() {
  let result = todo_validation.validate("", None, "medium")
  
  result
  |> should.be_error()
  |> should.equal(["title is required"])
}
