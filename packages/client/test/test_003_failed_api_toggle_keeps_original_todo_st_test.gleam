// REQUIRED data-testid attributes:
// - todo-item-{id}: container for each todo item
// - todo-checkbox-{id}: completion checkbox
// - todo-error: error message display area
//
// Test: Verify GotToggleResult(Error(_)) reverts checkbox state by not updating model and shows error

import gleeunit
import gleeunit/should
import frontend/model
import frontend/msg
import frontend/update
import shared.{Todo, Low}
import gleam/list
import gleam/option.{None}

pub fn main() {
  gleeunit.main()
}

pub fn failed_toggle_preserves_original_state_and_shows_error_test() {
  let test_original_todo = Todo(
    id: "todo-789",
    title: "Stay Incomplete",
    description: None,
    priority: Low,
    completed: False
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

  let msg = msg.ToggleResult(Error(msg.NetworkError))
  let #(new_model, effect) = update.update(initial_model, msg)

  case new_model.todos {
    [the_todo] -> {
      the_todo.completed |> should.equal(False)
      the_todo.id |> should.equal("todo-789")
    }
    _ -> should.equal(1, list.length(new_model.todos))
  }

  new_model.loading |> should.equal(False)
  new_model.error |> should.not_equal("")
  new_model.error |> should.equal("Failed to toggle todo. Please try again.")
  effect |> should.equal(update.none())
}
