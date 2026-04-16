import gleeunit
import gleeunit/should
import frontend/model
import shared

pub fn main() {
  gleeunit.main()
}

/// Test that default model has correct initial values
pub fn default_model_test() {
  let m = model.default()
  m.todos |> should.equal([])
  m.filter |> should.equal(model.All)
  m.form_title |> should.equal("")
  m.form_description |> should.equal(option.None)
  m.form_priority |> should.equal("medium")
  m.loading |> should.be_false
  m.error |> should.equal("")
}

/// Test model has_todos helper function
pub fn model_has_todos_test() {
  let empty_model = model.default()
  model.has_todos(empty_model) |> should.be_false

  let with_todos = model.Model(
    todos: [shared.Todo(id: "1", title: "Test", description: option.None, priority: shared.High, completed: False)],
    filter: model.All,
    form_title: "",
    form_description: option.None,
    form_priority: "medium",
    loading: False,
    error: ""
  )
  model.has_todos(with_todos) |> should.be_true
}

/// Test active_count helper function
pub fn model_active_count_test() {
  let todos = [
    shared.Todo(id: "1", title: "Active 1", description: option.None, priority: shared.High, completed: False),
    shared.Todo(id: "2", title: "Active 2", description: option.None, priority: shared.Medium, completed: False),
    shared.Todo(id: "3", title: "Completed", description: option.None, priority: shared.Low, completed: True),
  ]
  let m = model.Model(
    todos: todos,
    filter: model.All,
    form_title: "",
    form_description: option.None,
    form_priority: "medium",
    loading: False,
    error: ""
  )
  model.active_count(m) |> should.equal(2)
}

/// Test filter_todos function with All filter
pub fn filter_todos_all_test() {
  let todos = [
    shared.Todo(id: "1", title: "Active", description: option.None, priority: shared.High, completed: False),
    shared.Todo(id: "2", title: "Completed", description: option.None, priority: shared.Medium, completed: True),
  ]
  let m = model.Model(
    todos: todos,
    filter: model.All,
    form_title: "",
    form_description: option.None,
    form_priority: "medium",
    loading: False,
    error: ""
  )
  let filtered = model.filter_todos(m)
  list.length(filtered) |> should.equal(2)
}

/// Test filter_todos function with Active filter
pub fn filter_todos_active_test() {
  let todos = [
    shared.Todo(id: "1", title: "Active", description: option.None, priority: shared.High, completed: False),
    shared.Todo(id: "2", title: "Completed", description: option.None, priority: shared.Medium, completed: True),
  ]
  let m = model.Model(
    todos: todos,
    filter: model.Active,
    form_title: "",
    form_description: option.None,
    form_priority: "medium",
    loading: False,
    error: ""
  )
  let filtered = model.filter_todos(m)
  list.length(filtered) |> should.equal(1)
  case filtered {
    [first] -> first.id |> should.equal("1")
    _ -> should.fail()
  }
}

/// Test filter_todos function with Completed filter
pub fn filter_todos_completed_test() {
  let todos = [
    shared.Todo(id: "1", title: "Active", description: option.None, priority: shared.High, completed: False),
    shared.Todo(id: "2", title: "Completed", description: option.None, priority: shared.Medium, completed: True),
  ]
  let m = model.Model(
    todos: todos,
    filter: model.Completed,
    form_title: "",
    form_description: option.None,
    form_priority: "medium",
    loading: False,
    error: ""
  )
  let filtered = model.filter_todos(m)
  list.length(filtered) |> should.equal(1)
  case filtered {
    [first] -> first.id |> should.equal("2")
    _ -> should.fail()
  }
}

// Import for tests
import gleam/list
import gleam/option
