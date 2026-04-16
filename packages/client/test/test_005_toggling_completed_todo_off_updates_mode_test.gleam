// REQUIRED data-testid attributes:
// - todo-item-{id}: container for each todo item
// - todo-checkbox-{id}: completion checkbox
// - todo-text-{id}: text display (strikethrough removed when uncompleted)
//
// Test: Verify toggling from completed True to False updates model correctly

import gleeunit
import gleeunit/should
import frontend/model
import frontend/msg
import frontend/update
import shared.{Todo, Medium}
import gleam/list
import gleam/option.{None}

pub fn main() {
  gleeunit.main()
}

pub fn toggle_off_updates_todo_to_uncompleted_test() {
  let test_completed_todo = Todo(
    id: "todo-uncomplete",
    title: "Uncomplete Me",
    description: None,
    priority: Medium,
    completed: True
  )

  let test_uncompleted_todo = Todo(
    id: "todo-uncomplete",
    title: "Uncomplete Me",
    description: None,
    priority: Medium,
    completed: False
  )

  let initial_model = model.Model(
    todos: [test_completed_todo],
    filter: model.All,
    error: "",
    loading: True,
    form_title: "",
    form_description: "",
    form_priority: shared.Medium
  )

  let msg = msg.GotToggleResult(Ok(test_uncompleted_todo))
  let #(new_model, _effect) = update.update(initial_model, msg)

  case new_model.todos {
    [the_todo] -> the_todo.completed |> should.equal(False)
    _ -> should.equal(1, list.length(new_model.todos))
  }

  new_model.loading |> should.equal(False)
}
