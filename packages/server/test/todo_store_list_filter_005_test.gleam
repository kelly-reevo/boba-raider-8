// Behavioral test: list_all with invalid filter value gracefully defaults to all
// Boundary contract: list_all(filter: 'all'|'active'|'completed') -> {:ok, Todo[]}

import gleeunit/should
import gleam/list
import gleam/option.{Some, None}
import todo_store
import shared.{UpdateTodoInput}

// EDGE CASE: Invalid filter value gracefully defaults to returning all todos
// Test type: integration (tests error handling at store boundary)
pub fn list_all_invalid_filter_defaults_to_all_test() {
  // Setup: Start store with mix of todos
  let assert Ok(store) = todo_store.start()
  let assert Ok(_) = todo_store.create_todo(store, "Active", "To do")
  let assert Ok(completed) = todo_store.create_todo(store, "Completed", "Done")
  let input = UpdateTodoInput(
    title: None,
    description: None,
    completed: Some(True),
  )
  let assert Ok(_) = todo_store.update_todo(store, completed.id, input)

  // Action: Call list_all with invalid filter value
  let result = todo_store.list_all(store, "invalid_filter_value")

  // Assert: Still returns Ok (graceful handling)
  let assert Ok(todos) = result

  // Assert: Returns all todos (2 in this case)
  should.equal(list.length(todos), 2)
}
