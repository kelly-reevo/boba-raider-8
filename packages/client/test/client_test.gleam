import gleeunit
import gleeunit/should
import frontend/model

pub fn main() {
  gleeunit.main()
}

pub fn default_model_test() {
  let m = model.default()

  // Default model should have loading states set to false
  m.stores_loading
  |> should.equal(False)

  m.drink_loading
  |> should.equal(False)

  m.rating_submitting
  |> should.equal(False)

  // Default model should have empty lists
  m.stores
  |> should.equal([])

  m.drink_ratings
  |> should.equal([])
}
