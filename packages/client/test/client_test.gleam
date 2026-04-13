import gleeunit
import gleeunit/should
import frontend/model

pub fn main() {
  gleeunit.main()
}

pub fn default_model_test() {
  let m = model.default()
  // Check default values in new model
  m.title_input
  |> should.equal("")

  m.description_input
  |> should.equal("")

  m.error
  |> should.equal("")

  m.todos
  |> should.equal([])
}

pub fn loading_states_test() {
  let m = model.default()

  // Test setting list loading state
  let loading_model = model.set_list_loading(m, model.Loading)
  model.is_loading(loading_model)
  |> should.be_true()

  // Test setting form loading state
  let form_loading_model = model.set_form_loading(m, model.Loading)
  model.is_form_submitting(form_loading_model)
  |> should.be_true()

  // Test setting todo loading state
  let todo_loading_model = model.set_todo_loading(m, "1", model.Loading)
  model.is_todo_loading(todo_loading_model, "1")
  |> should.be_true()
}
