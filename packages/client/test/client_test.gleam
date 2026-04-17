import atlas
import frontend/model
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn init_starts_at_overview_test() {
  let m = model.init()
  m.level
  |> should.equal(atlas.Overview)
}

pub fn init_has_no_stack_test() {
  let m = model.init()
  m.stack
  |> should.equal([])
}
