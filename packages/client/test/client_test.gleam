import gleeunit
import gleeunit/should
import frontend/model.{Home, Anonymous}

pub fn main() {
  gleeunit.main()
}

/// Test that default model initializes correctly
pub fn default_model_test() {
  let m = model.default()
  m.current_page
  |> should.equal(Home)
}

pub fn default_model_auth_test() {
  let m = model.default()
  m.auth
  |> should.equal(Anonymous)
}
