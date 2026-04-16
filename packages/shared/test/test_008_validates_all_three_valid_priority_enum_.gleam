import gleeunit/should
import shared/todo_validation
import gleam/option.{None}

pub fn all_valid_priority_values_accepted_test() {
  let low_result = todo_validation.validate("Task 1", None, "low")
  let medium_result = todo_validation.validate("Task 2", None, "medium")
  let high_result = todo_validation.validate("Task 3", None, "high")
  
  low_result |> should.be_ok()
  let assert Ok(low_val) = low_result
  low_val.priority |> should.equal("low")

  medium_result |> should.be_ok()
  let assert Ok(med_val) = medium_result
  med_val.priority |> should.equal("medium")

  high_result |> should.be_ok()
  let assert Ok(high_val) = high_result
  high_val.priority |> should.equal("high")
}
