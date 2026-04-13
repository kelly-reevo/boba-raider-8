// Behavioral test: Verify list_all returns correct result type per boundary contract
// Boundary contract: list_all(filter: 'all'|'active'|'completed') -> {:ok, Todo[]}

import gleeunit/should
import gleam/list
import gleam/string
import todo_store
import shared.{type Todo}

// BOUNDARY CONTRACT VALIDATION: list_all returns {:ok, Todo[]} result type
// Test type: integration (tests return type contract at store boundary)
pub fn list_all_returns_ok_result_type_test() {
  // Setup: Start store and create a todo
  let assert Ok(store) = todo_store.start()
  let assert Ok(created) = todo_store.create_todo(store, "Test Todo", "Description")
  
  // Action: Call list_all with filter=all
  let result = todo_store.list_all(store, "all")
  
  // Assert: Returns Ok variant (not raw list)
  let assert Ok(todos) = result
  
  // Assert: Inner value is a list of Todos
  should.equal(list.length(todos), 1)
  
  // Assert: Todo has all required fields per data contract
  let assert Ok(first) = list.first(todos)
  should.be_true(string.length(first.id) > 0)
  should.equal(first.title, "Test Todo")
  should.equal(first.description, "Description")
  should.be_false(first.completed)
  should.be_true(first.created_at > 0)
  should.be_true(first.updated_at > 0)
}
