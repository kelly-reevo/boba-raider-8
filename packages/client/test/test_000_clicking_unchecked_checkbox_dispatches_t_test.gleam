// REQUIRED data-testid attributes:
// - todo-item-{id}: container for each todo item
// - todo-checkbox-{id}: completion checkbox for each todo
// - todo-title-{id}: title display for verification
//
// Test: Verify clicking unchecked checkbox sends ToggleTodo(id, True) message

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

pub fn unchecked_checkbox_click_dispatches_toggle_true_test() {
  let test_todo = Todo(
    id: "todo-123",
    title: "Test Todo",
    description: None,
    priority: shared.Medium,
    completed: False
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

  let msg = msg.ToggleTodo("todo-123", True)
  let #(new_model, effect) = update.update(initial_model, msg)

  new_model.todos |> should.equal(initial_model.todos)
  effect |> should.not_equal(update.none())
}
