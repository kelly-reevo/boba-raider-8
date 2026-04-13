import gleeunit
import gleeunit/should
import frontend/model

pub fn main() {
  gleeunit.main()
}

pub fn default_model_test() {
  let m = model.default()
  // AppModel starts with is_loading = True
  m.is_loading
  |> should.equal(True)
}

pub fn default_model_todos_empty_test() {
  let m = model.default()
  m.todos
  |> should.equal([])
}

pub fn default_model_form_input_empty_test() {
  let m = model.default()
  m.form_input
  |> should.equal("")
}
