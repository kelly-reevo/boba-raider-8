import gleeunit
import gleeunit/should
import frontend/model

pub fn main() {
  gleeunit.main()
}

pub fn init_model_test() {
  let m = model.init()
  m.is_loading
  |> should.equal(True)

  m.loading_message
  |> should.equal("Loading todos...")

  m.submit_button_text
  |> should.equal("Add Todo")
}

pub fn init_model_todos_empty_test() {
  let m = model.init()
  m.todos
  |> should.equal([])
}

pub fn init_model_form_fields_empty_test() {
  let m = model.init()
  m.new_todo_title
  |> should.equal("")
  m.new_todo_description
  |> should.equal("")
}
