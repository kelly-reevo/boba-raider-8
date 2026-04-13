import gleeunit
import gleeunit/should
import frontend/model
import shared.{Medium}

pub fn main() {
  gleeunit.main()
}

pub fn default_model_test() {
  let m = model.default()
  // Verify model has expected default state
  m.error |> should.equal("")
  m.form.title |> should.equal("")
  m.form.description |> should.equal("")
  m.form.priority |> should.equal(Medium)
  m.todos |> should.equal([])
}
