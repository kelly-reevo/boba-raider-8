import gleeunit
import gleeunit/should
import frontend/model.{Home, Anonymous}

pub fn main() {
  gleeunit.main()
}

/// Test that default model initializes correctly
pub fn default_model_test() {
  let m = model.default()
  case m.current_page {
    model.HomePage -> True
    _ -> False
  }
  |> should.equal(True)
}
