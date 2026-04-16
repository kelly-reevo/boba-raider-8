import gleeunit/should
import shared/todo_validation
import gleam/option.{Some}
import gleam/string

pub fn description_at_max_length_is_valid_test() {
  let max_description = string.repeat("y", 1000)
  let result = todo_validation.validate("Valid Title", Some(max_description), "low")
  
  result
  |> should.be_ok()
}
