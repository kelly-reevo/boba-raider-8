// Behavioral test: list_all filter=active returns only incomplete todos
// Boundary contract: list_all(filter: 'all'|'active'|'completed') -> {:ok, Todo[]}

import gleeunit/should
import gleam/list
import gleam/int
import gleam/order
import gleam/option.{Some, None}
import todo_store.{type Todo}
import shared.{UpdateTodoInput}

// Helper: Create a completed todo by creating then updating
fn create_completed_todo(store, title, description) {
  let assert Ok(item) = todo_store.create_todo(store, title, description)
  let input = UpdateTodoInput(
    title: None,
    description: None,
    completed: Some(True),
  )
  let assert Ok(completed) = todo_store.update_todo(store, item.id, input)
  completed
}

// Helper: Verify list is sorted by created_at descending (newest first)
fn assert_newest_first(todos: List(Todo)) {
  let timestamps = list.map(todos, fn(t) { t.created_at })
  let sorted = list.sort(timestamps, fn(a, b) { order.reverse(int.compare)(a, b) })
  should.equal(timestamps, sorted)
}

// ACCEPTANCE CRITERION: Given todos with mixed completion status, when list with filter=active, then only completed=false todos returned
// Test type: integration (tests store public interface boundary contract)
pub fn list_all_filter_active_returns_only_incomplete_test() {
  // Setup: Start store with mix of completed and incomplete todos
  let assert Ok(store) = todo_store.start()
  let assert Ok(active1) = todo_store.create_todo(store, "Active Todo 1", "Do this")
  let _completed1 = create_completed_todo(store, "Done 1", "Already done")
  let assert Ok(active2) = todo_store.create_todo(store, "Active Todo 2", "Do that")
  let _completed2 = create_completed_todo(store, "Done 2", "Finished")
  let assert Ok(active3) = todo_store.create_todo(store, "Active Todo 3", "And this")
  
  // Action: List with filter=active
  let result = todo_store.list_all(store, "active")
  
  // Assert: Returns Ok with only 3 active todos
  let assert Ok(todos) = result
  should.equal(list.length(todos), 3)
  
  // Assert: All returned todos have completed=false
  list.each(todos, fn(t) {
    should.be_false(t.completed)
  })
  
  // Assert: Contains expected active todos
  let ids = list.map(todos, fn(t) { t.id })
  should.be_true(list.contains(ids, active1.id))
  should.be_true(list.contains(ids, active2.id))
  should.be_true(list.contains(ids, active3.id))
  
  // Assert: Sorted newest-first
  assert_newest_first(todos)
  
  // Assert: Newest active todo is first
  let assert Ok(first) = list.first(todos)
  should.equal(first.id, active3.id)
}
