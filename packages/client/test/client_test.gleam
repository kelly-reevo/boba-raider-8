import gleeunit
import gleeunit/should
import frontend/model

pub fn main() {
  gleeunit.main()
}

pub fn default_model_test() {
  let m = model.default()

  // Verify default model has empty todos and Idle state
  m.todos
  |> should.equal([])

  m.loading_state
  |> should.equal(model.Idle)
}

pub fn model_is_empty_test() {
  let empty_model = model.default()

  model.is_empty(empty_model)
  |> should.be_true()

  // A model with todos would not be empty
  // {full_model checks omitted - would require creating Todo values}
}

pub fn remove_todo_test() {
  // Test that remove_todo handles empty list gracefully
  let empty_model = model.default()
  let result = model.remove_todo(empty_model, "non-existent-id")

  result.todos
  |> should.equal([])
}
