// REQUIRED data-testid attributes:
// - todo-item-{id}: container for each todo item
// - todo-checkbox-{id}: completion checkbox
// - todo-text-{id}: text display with strikethrough when completed
//
// Test: Verify GotToggleResult(Ok(updated_todo)) updates model and marks todo completed

import gleeunit
import gleeunit/should
import frontend/model
import frontend/msg
import frontend/update
import shared.{Todo, High}
import gleam/list
import gleam/option.{None}

pub fn main() {
  gleeunit.main()
}

pub fn successful_toggle_updates_todo_completed_state_test() {
  let test_original_todo = Todo(
    id: "todo-456",
    title: "Complete Me",
    description: None,
    priority: High,
    completed: False
  )

  let test_updated_todo = Todo(
    id: "todo-456",
    title: "Complete Me",
    description: None,
    priority: High,
    completed: True
  )

  let initial_model = model.Model(
    todos: [test_original_todo],
    filter: model.All,
    error: "",
    delete_confirming_id: None,
    loading: True,
    form_title: "",
    form_description: None,
    form_priority: "medium"
  )

  let msg = msg.ToggleResult(Ok(test_updated_todo))
  let #(new_model, effect) = update.update(initial_model, msg)

  case new_model.todos {
    [the_todo] -> {
      the_todo.completed |> should.equal(True)
      the_todo.id |> should.equal("todo-456")
    }
    _ -> should.equal(1, list.length(new_model.todos))
  }

  new_model.loading |> should.equal(False)
  new_model.error |> should.equal("")
  effect |> should.equal(update.none())
}
