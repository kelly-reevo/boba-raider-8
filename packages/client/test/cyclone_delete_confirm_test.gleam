// === REQUIRED data-testid ATTRIBUTES ===
// - delete-btn-{id}: Delete button on each todo item
// - todo-item-{id}: Container for each todo item in the list
// - error-message: Error display element
// - confirm-dialog: Confirmation dialog overlay
// - confirm-delete-btn: Confirm delete action button
// - cancel-delete-btn: Cancel delete action button
// - todo-title-{id}: Title text of todo item

import gleeunit/should
import frontend/model
import frontend/msg
import frontend/update
import frontend/effects
import gleam/option.{None, Some}
import shared.{Medium, Low, Todo}

// Test first click shows confirmation (two-phase delete)
pub fn first_delete_click_shows_confirmation_test() {
  let todo_id = "todo-123"
  let initial_model = model.Model(
    todos: [Todo(id: todo_id, title: "Test", description: None, priority: Medium, completed: False)],
    error: "",
    delete_confirming_id: None,
    filter: model.All,
    form_title: "",
    form_description: None,
    form_priority: "medium",
    loading: False,
  )

  let #(new_model, effect) = update.update(initial_model, msg.DeleteClicked(todo_id))

  // Model should enter confirmation state for this todo
  new_model.delete_confirming_id |> should.equal(Some(todo_id))

  // No API call yet
  effects.effect_to_json(effect) |> should.equal("{\"type\":\"none\"}")
}

// Test second click on same todo performs delete
pub fn second_delete_click_confirms_deletion_test() {
  let todo_id = "todo-123"
  let initial_model = model.Model(
    todos: [Todo(id: todo_id, title: "Test", description: None, priority: Medium, completed: False)],
    error: "",
    delete_confirming_id: Some(todo_id),
    filter: model.All,
    form_title: "",
    form_description: None,
    form_priority: "medium",
    loading: False,
  )

  let #(new_model, effect) = update.update(initial_model, msg.DeleteClicked(todo_id))

  // Confirmation state cleared
  new_model.delete_confirming_id |> should.equal(None)

  // API effect triggered
  effects.effect_to_json(effect) |> should.equal("{\"type\":\"delete_todo\",\"id\":\"todo-123\"}")
}

// Test clicking different todo cancels first confirmation
pub fn clicking_different_todo_switches_confirmation_test() {
  let todo1_id = "todo-123"
  let todo2_id = "todo-456"
  let initial_model = model.Model(
    todos: [
      Todo(id: todo1_id, title: "First", description: None, priority: Medium, completed: False),
      Todo(id: todo2_id, title: "Second", description: None, priority: Low, completed: False)
    ],
    error: "",
    delete_confirming_id: Some(todo1_id),
    filter: model.All,
    form_title: "",
    form_description: None,
    form_priority: "medium",
    loading: False,
  )

  let #(new_model, effect) = update.update(initial_model, msg.DeleteClicked(todo2_id))

  // Now confirming second todo, not first
  new_model.delete_confirming_id |> should.equal(Some(todo2_id))

  // No API call yet
  effects.effect_to_json(effect) |> should.equal("{\"type\":\"none\"}")
}

// Test cancel action clears confirmation state
pub fn cancel_delete_clears_confirmation_test() {
  let todo_id = "todo-123"
  let initial_model = model.Model(
    todos: [Todo(id: todo_id, title: "Test", description: None, priority: Medium, completed: False)],
    error: "",
    delete_confirming_id: Some(todo_id),
    filter: model.All,
    form_title: "",
    form_description: None,
    form_priority: "medium",
    loading: False,
  )

  let #(new_model, effect) = update.update(initial_model, msg.CancelDelete)

  // Confirmation cleared
  new_model.delete_confirming_id |> should.equal(None)
  new_model.todos |> should.equal(initial_model.todos)

  // No effects
  effects.effect_to_json(effect) |> should.equal("{\"type\":\"none\"}")
}
