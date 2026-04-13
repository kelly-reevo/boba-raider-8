import gleeunit
import gleeunit/should
import frontend/model

pub fn main() {
  gleeunit.main()
}

pub fn default_model_test() {
  let m = model.default()
  m.todos
  |> should.equal([])
}
