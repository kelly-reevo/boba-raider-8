import gleeunit
import gleeunit/should
import gleam/option
import frontend/model

pub fn main() {
  gleeunit.main()
}

pub fn default_model_test() {
  let m = model.default()
  m.page |> should.equal(model.HomePage)
  m.store |> should.equal(option.None)
  m.drinks |> should.equal([])
  m.loading |> should.equal(False)
  m.error |> should.equal("")
}
