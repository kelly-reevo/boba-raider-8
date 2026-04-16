import gleeunit/should
import shared/todo_validation
import gleam/option.{None}
import gleam/string

pub fn title_too_long_returns_error_test() {
  let long_title = string.repeat("a", 201)
  let result = todo_validation.validate(long_title, None, "medium")
  
  result
  |> should.be_error()
  |> should.equal(["title too long"])
}
