import gleeunit/should
import shared/todo_validation
import gleam/option.{None}

pub fn valid_inputs_no_description_return_ok_test() {
  let result = todo_validation.validate("Simple task", None, "low")
  
  result
  |> should.be_ok()
  |> fn(validated) {
    validated.title |> should.equal("Simple task")
    validated.description |> should.equal(None)
    validated.priority |> should.equal("low")
  }
}
