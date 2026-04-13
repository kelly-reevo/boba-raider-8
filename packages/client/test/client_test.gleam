import gleeunit
import gleeunit/should
import frontend/model.{Idle}

pub fn main() {
  gleeunit.main()
}

pub fn default_model_test() {
  let m = model.default()
  m.status
  |> should.equal(Idle)
}
