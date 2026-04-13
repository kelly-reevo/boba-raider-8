import gleeunit
import gleeunit/should
import frontend/model

pub fn main() {
  gleeunit.main()
}

pub fn default_model_test() {
  let m = model.default()
  should.equal(m.loading, False)
  should.equal(m.error, "")
  should.equal(m.todos, [])
  should.equal(m.toggling_id, "")
}
