import gleeunit
import gleeunit/should
import gleam/option
import frontend/model

pub fn main() {
  gleeunit.main()
}

pub fn default_model_test() {
  let m = model.default()
  m.page
  |> should.equal(model.LoginPage)
  m.token
  |> should.equal(option.None)
  m.loading
  |> should.equal(False)
  m.error
  |> should.equal("")
}
