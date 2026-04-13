import gleeunit
import gleeunit/should
import frontend/model.{Loading, All, Idle}
import shared.{Todo, Medium}
import gleam/option.{None}
import gleam/list

pub fn main() {
  gleeunit.main()
}

pub fn default_model_test() {
  let m = model.default()

  m.todos |> should.equal([])
  m.filter |> should.equal(All)
  m.data_state |> should.equal(Loading)
  m.error |> should.equal("")
  m.form.title |> should.equal("")
  m.form.description |> should.equal("")
  m.form.priority |> should.equal(Medium)
  m.submit_state |> should.equal(Idle)
  m.deleting_id |> should.equal(None)
}

pub fn filter_todos_all_test() {
  let todos = [
    Todo("1", "Todo 1", None, "medium", False, 0, 0),
    Todo("2", "Todo 2", None, "medium", True, 0, 0),
  ]

  model.filter_todos(todos, All)
  |> should.equal(todos)
}

pub fn filter_todos_active_test() {
  let active_todo = Todo("1", "Active", None, "medium", False, 0, 0)
  let completed_todo = Todo("2", "Completed", None, "medium", True, 0, 0)
  let todos = [active_todo, completed_todo]

  model.filter_todos(todos, model.Active)
  |> should.equal([active_todo])
}

pub fn filter_todos_completed_test() {
  let active_todo = Todo("1", "Active", None, "medium", False, 0, 0)
  let completed_todo = Todo("2", "Completed", None, "medium", True, 0, 0)
  let todos = [active_todo, completed_todo]

  model.filter_todos(todos, model.Completed)
  |> should.equal([completed_todo])
}

pub fn remove_todo_test() {
  let m = model.Model(
    todos: [
      Todo(id: "1", title: "First", description: None, priority: "high", completed: False, created_at: 0, updated_at: 0),
      Todo(id: "2", title: "Second", description: None, priority: "low", completed: True, created_at: 0, updated_at: 0),
    ],
    filter: All,
    data_state: Loaded,
    form: model.FormState(title: "", description: "", priority: Medium),
    submit_state: Idle,
    error: "",
    deleting_id: None,
  )

  let updated = model.remove_todo(m, "1")

  updated.todos |> list.length |> should.equal(1)
  updated.deleting_id |> should.equal(None)
}

pub fn set_deleting_test() {
  let m = model.default()
  let updated = model.set_deleting(m, "123")

  updated.deleting_id |> should.equal(gleam/option.Some("123"))
}

pub fn update_todo_completed_test() {
  let m = model.Model(
    todos: [
      Todo(id: "1", title: "First", description: None, priority: "high", completed: False, created_at: 0, updated_at: 0),
    ],
    filter: All,
    data_state: Loaded,
    form: model.FormState(title: "", description: "", priority: Medium),
    submit_state: Idle,
    error: "",
    deleting_id: None,
  )

  let updated = model.update_todo_completed(m, "1", True)

  case updated.todos {
    [item] -> item.completed |> should.equal(True)
    _ -> should.fail()
  }
}
