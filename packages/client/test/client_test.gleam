import gleeunit
import gleeunit/should
import frontend/model.{Todo, Idle, Loading, Error}
import gleam/option.{Some, None}
import gleam/list

pub fn main() {
  gleeunit.main()
}

pub fn default_model_test() {
  let m = model.default()
  m.todos |> list.length |> should.equal(0)
  m.loading_state |> should.equal(Idle)
  m.deleting_id |> should.equal(None)
}

pub fn remove_todo_test() {
  let m = model.Model(
    todos: [
      Todo(id: "1", title: "First", priority: "high", completed: False),
      Todo(id: "2", title: "Second", priority: "low", completed: True),
    ],
    loading_state: Idle,
    deleting_id: None,
  )

  let updated = model.remove_todo(m, "1")

  updated.todos |> list.length |> should.equal(1)
  updated.deleting_id |> should.equal(None)

  // Verify correct todo was removed
  case updated.todos {
    [item] -> item.id |> should.equal("2")
    _ -> should.fail()
  }
}

pub fn set_deleting_test() {
  let m = model.default()
  let updated = model.set_deleting(m, "123")

  updated.deleting_id |> should.equal(Some("123"))
}

pub fn set_error_test() {
  let m = model.Model(
    todos: [],
    loading_state: Loading,
    deleting_id: Some("123"),
  )

  let updated = model.set_error(m, "Failed to delete")

  updated.loading_state |> should.equal(Error("Failed to delete"))
  updated.deleting_id |> should.equal(None)
}

pub fn clear_error_test() {
  let m = model.Model(
    todos: [],
    loading_state: Error("Something went wrong"),
    deleting_id: None,
  )

  let updated = model.clear_error(m)

  updated.loading_state |> should.equal(Idle)
}
