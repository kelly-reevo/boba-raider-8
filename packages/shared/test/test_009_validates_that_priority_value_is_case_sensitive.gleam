import gleeunit/should
import shared/todo_validation
import gleam/option.{None}

pub fn priority_is_case_sensitive_test() {
  let result_uppercase = todo_validation.validate("Task", None, "HIGH")
  let result_mixed = todo_validation.validate("Task", None, "Low")
  
  result_uppercase |> should.be_error()
  result_mixed |> should.be_error()
}
