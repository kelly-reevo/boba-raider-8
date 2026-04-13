import gleeunit
import gleeunit/should
import frontend/model
import gleam/option

pub fn main() {
  gleeunit.main()
}

pub fn default_model_test() {
  let m = model.default()

  // Check that default model has empty todos and is loading
  m.todos
  |> should.equal([])

  m.loading
  |> should.equal(True)

  m.filter
  |> should.equal(model.All)
}

pub fn empty_state_filter_all_test() {
  // When no todos and filter is All, should show "No todos yet" message
  let m = model.default()
  let filtered = model.filter_todos(m)

  filtered
  |> should.equal([])
}

pub fn empty_state_filter_active_test() {
  // When filter is Active and no active todos, should show "No active todos" message
  let m = model.Model(
    todos: [],
    filter: model.Active,
    loading: False,
    error: option.None,
    form: model.FormState("", "", "medium"),
  )
  let filtered = model.filter_todos(m)

  filtered
  |> should.equal([])
}

pub fn empty_state_filter_completed_test() {
  // When filter is Completed and no completed todos, should show "No completed todos" message
  let m = model.Model(
    todos: [],
    filter: model.Completed,
    loading: False,
    error: option.None,
    form: model.FormState("", "", "medium"),
  )
  let filtered = model.filter_todos(m)

  filtered
  |> should.equal([])
}
