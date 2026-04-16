// REQUIRED data-testid attributes:
// - todo-item-{id}: container for each todo item
// - todo-checkbox-{id}: completion checkbox for each todo
//
// Test: Verify toggling one todo does not affect other todos in the list

import gleeunit
import gleeunit/should
import frontend/model
import frontend/msg
import frontend/update
import shared.{Todo, Low, Medium, High}
import gleam/list
import gleam/option.{None}

pub fn main() {
  gleeunit.main()
}

pub fn toggle_only_affects_targeted_todo_test() {
  let test_todo1 = Todo(
    id: "todo-1",
    title: "First",
    description: None,
    priority: Low,
    completed: False
  )

  let test_todo2 = Todo(
    id: "todo-2",
    title: "Second",
    description: None,
    priority: Medium,
    completed: False
  )

  let test_todo3 = Todo(
    id: "todo-3",
    title: "Third",
    description: None,
    priority: High,
    completed: True
  )

  let test_updated_todo2 = Todo(
    id: "todo-2",
    title: "Second",
    description: None,
    priority: Medium,
    completed: True
  )

  let initial_model = model.Model(
    todos: [test_todo1, test_todo2, test_todo3],
    filter: model.All,
    error: "",
    delete_confirming_id: None,
    loading: False,
    form_title: "",
    form_description: None,
    form_priority: "medium"
  )

  let msg = msg.ToggleResult(Ok(test_updated_todo2))
  let #(new_model, _effect) = update.update(initial_model, msg)

  case new_model.todos {
    [t1, t2, t3] -> {
      t1.completed |> should.equal(False)
      t2.completed |> should.equal(True)
      t2.id |> should.equal("todo-2")
      t3.completed |> should.equal(True)
    }
    _ -> should.equal(3, list.length(new_model.todos))
  }
}
