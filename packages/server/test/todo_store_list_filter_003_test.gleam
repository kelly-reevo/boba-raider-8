// Behavioral test: list_all on empty store returns empty list
// Boundary contract: list_all(filter: 'all'|'active'|'completed') -> {:ok, Todo[]}

import gleeunit/should
import gleam/list
import todo_store

// ACCEPTANCE CRITERION: Given empty store, when list is called, then empty list returned
// Test type: integration (tests store public interface boundary contract)
pub fn list_all_empty_store_returns_empty_list_test() {
  // Setup: Start store without creating any todos
  let assert Ok(store) = todo_store.start()
  
  // Action: List with filter=all on empty store
  let result_all = todo_store.list_all(store, "all")
  
  // Assert: Returns Ok with empty list for filter=all
  let assert Ok(todos_all) = result_all
  should.equal(list.length(todos_all), 0)
  should.equal(todos_all, [])
  
  // Action: List with filter=active on empty store
  let result_active = todo_store.list_all(store, "active")
  
  // Assert: Returns Ok with empty list for filter=active
  let assert Ok(todos_active) = result_active
  should.equal(list.length(todos_active), 0)
  
  // Action: List with filter=completed on empty store
  let result_completed = todo_store.list_all(store, "completed")
  
  // Assert: Returns Ok with empty list for filter=completed
  let assert Ok(todos_completed) = result_completed
  should.equal(list.length(todos_completed), 0)
}
