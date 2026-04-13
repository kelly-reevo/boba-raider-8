import gleeunit
import gleeunit/should
import frontend/model
import gleam/option

pub fn main() {
  gleeunit.main()
}

pub fn default_model_test() {
  let m = model.default()
  // Model should have empty todos list by default
  m.todos
  |> should.equal([])
}

pub fn default_model_has_no_error_test() {
  let m = model.default()
  // Model should have no error by default
  m.error
  |> should.equal(option.None)
}
