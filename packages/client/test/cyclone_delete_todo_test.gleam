// === REQUIRED data-testid ATTRIBUTES ===
// - delete-btn-{id}: Delete button on each todo item
// - todo-item-{id}: Container for each todo item in the list
// - error-message: Error display element
// - confirm-dialog: Confirmation dialog (if using inline)
// - confirm-delete-btn: Confirm delete action
// - cancel-delete-btn: Cancel delete action

import gleeunit/should
import frontend/model
import frontend/msg
import frontend/update
import frontend/effects
import gleam/option.{None}
import shared.{High, Medium, Low, Todo}

// Test that DeleteTodo message produces correct effect
pub fn delete_todo_triggers_api_effect_test() {
  let todo_id = "todo-123"
  let initial_model = model.Model(
    todos: [
      Todo(id: todo_id, title: "Test Todo", description: None, priority: Medium, completed: False)
    ],
    error: "",
    filter: model.All,
    delete_confirming_id: None,
    form_title: "",
    form_description: None,
    form_priority: "medium",
    loading: False,
  )

  let #(new_model, effect) = update.update(initial_model, msg.DeleteTodo(todo_id))

  // Model should not change yet (optimistic UI not required)
  new_model.todos |> should.equal(initial_model.todos)

  // Should produce delete effect
  effects.effect_to_json(effect) |> should.equal("{\"type\":\"delete_todo\",\"id\":\"todo-123\"}")
}

// Test successful delete response removes todo from model
pub fn delete_success_removes_todo_test() {
  let todo_id = "todo-123"
  let other_todo = Todo(id: "todo-456", title: "Other", description: None, priority: Low, completed: False)
  let initial_model = model.Model(
    todos: [
      Todo(id: todo_id, title: "To Delete", description: None, priority: Medium, completed: False),
      other_todo
    ],
    error: "",
    filter: model.All,
    delete_confirming_id: None,
    form_title: "",
    form_description: None,
    form_priority: "medium",
    loading: False,
  )

  let #(new_model, effect) = update.update(initial_model, msg.TodoDeleted(Ok(todo_id)))

  // Deleted todo should be removed
  new_model.todos |> should.equal([other_todo])
  new_model.error |> should.equal("")

  // Should produce fetch effect to refresh list
  effects.effect_to_json(effect) |> should.equal("{\"type\":\"fetch_todos\"}")
}

// Test failed delete keeps todo and shows error
pub fn delete_failure_preserves_todo_and_shows_error_test() {
  let todo_id = "todo-123"
  let item = Todo(id: todo_id, title: "Important", description: None, priority: High, completed: False)
  let initial_model = model.Model(
    todos: [item],
    error: "",
    filter: model.All,
    delete_confirming_id: None,
    form_title: "",
    form_description: None,
    form_priority: "medium",
    loading: False,
  )

  let #(new_model, effect) = update.update(initial_model, msg.TodoDeleted(Error(msg.NetworkError)))

  // Todo should still exist
  new_model.todos |> should.equal([item])

  // Error should be set
  new_model.error |> should.equal("Failed to delete todo: Network error. Please check your connection.")

  // No additional effects on failure
  effects.effect_to_json(effect) |> should.equal("{\"type\":\"none\"}")
}
