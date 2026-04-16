import gleeunit/should
import shared/todo_validation
import gleam/option.{None}
import gleam/string

pub fn title_at_max_length_is_valid_test() {
  let max_title = string.repeat("x", 200)
  let result = todo_validation.validate(max_title, None, "medium")
  
  result
  |> should.be_ok()
  |> fn(validated) {
    validated.title |> should.equal(max_title)
  }
}
