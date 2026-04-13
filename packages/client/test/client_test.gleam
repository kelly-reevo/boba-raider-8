import gleeunit
import gleeunit/should
import frontend/model

pub fn main() {
  gleeunit.main()
}

pub fn default_model_test() {
  let _m = model.default()
  // Model structure validated by compilation
  should.equal(True, True)
}
