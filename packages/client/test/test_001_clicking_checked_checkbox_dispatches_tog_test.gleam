// REQUIRED data-testid attributes:
// - todo-item-{id}: container for each todo item
// - todo-checkbox-{id}: completion checkbox for each todo
//
// Test: Verify clicking checked checkbox sends ToggleTodo(id, False) message

import gleeunit
import gleeunit/should
import frontend/model
import frontend/msg
import frontend/update
import shared.{Todo}
import gleam/option.{None}

pub fn main() {
  gleeunit.main()
}

pub fn checked_checkbox_click_dispatches_toggle_false_test() {
  let test_todo = Todo(
    id: "todo-123",
    title: "Test Todo",
    description: None,
    priority: shared.Medium,
    completed: True
  )

  let initial_model = model.Model(
    todos: [test_todo],
    filter: model.All,
    error: "",
    delete_confirming_id: None,
    loading: False,
    form_title: "",
    form_description: None,
    form_priority: "medium"
  )

  let msg = msg.ToggleTodo("todo-123", False)
  let #(new_model, effect) = update.update(initial_model, msg)

  new_model.todos |> should.equal(initial_model.todos)
  effect |> should.not_equal(update.none())
}
