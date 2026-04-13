import gleeunit
import gleeunit/should
import frontend/model

pub fn main() {
  gleeunit.main()
}

pub fn default_model_test() {
  let m = model.default()
  // Model should have empty todos, All filter, not loading, no error
  m.todos |> should.equal([])
  m.filter |> should.equal(model.All)
  m.loading |> should.equal(False)
  m.error |> should.equal("")
}
