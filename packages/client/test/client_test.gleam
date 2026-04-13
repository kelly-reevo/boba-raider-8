import gleeunit
import gleeunit/should
import frontend/model.{All}

pub fn main() {
  gleeunit.main()
}

pub fn default_model_test() {
  let m = model.default()
  m.todos
  |> should.equal([])
  m.filter
  |> should.equal(All)
  m.loading
  |> should.equal(False)
  m.error
  |> should.equal("")
}
