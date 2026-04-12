import gleeunit
import gleeunit/should
import frontend/model
import frontend/msg

pub fn main() {
  gleeunit.main()
}

pub fn default_model_test() {
  let m = model.default()
  // Model should have empty todos list by default
  m.todos
  |> should.equal([])
}

pub fn is_list_loading_test() {
  let m = model.default()
  // Default model should not be loading
  model.is_list_loading(m)
  |> should.equal(False)
}

pub fn add_loading_test() {
  let m = model.default()
  let with_loading = model.add_loading(m, msg.ListLoading)
  model.is_list_loading(with_loading)
  |> should.equal(True)
}
