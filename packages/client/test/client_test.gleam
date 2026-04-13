import gleeunit
import gleeunit/should
import frontend/model.{Loading, All}
import shared.{Todo}
import gleam/option.{None}

pub fn main() {
  gleeunit.main()
}

pub fn default_model_test() {
  let m = model.default()

  m.todos
  |> should.equal([])

  m.filter
  |> should.equal(All)

  m.data_state
  |> should.equal(Loading)
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
