// Behavioral test: list_all filter=completed returns only completed todos
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

// ACCEPTANCE CRITERION: Given todos with mixed completion status, when list with filter=completed, then only completed=true todos returned
// Test type: integration (tests store public interface boundary contract)
pub fn list_all_filter_completed_returns_only_completed_test() {
  // Setup: Start store with mix of completed and incomplete todos
  let assert Ok(store) = todo_store.start()
  let _active1 = todo_store.create_todo(store, "Active 1", "Still to do")
  let completed1 = create_completed_todo(store, "Completed Todo 1", "Done")
  let _active2 = todo_store.create_todo(store, "Active 2", "Also to do")
  let completed2 = create_completed_todo(store, "Completed Todo 2", "Finished")
  let completed3 = create_completed_todo(store, "Completed Todo 3", "Complete")
  
  // Action: List with filter=completed
  let result = todo_store.list_all(store, "completed")
  
  // Assert: Returns Ok with only 3 completed todos
  let assert Ok(todos) = result
  should.equal(list.length(todos), 3)
  
  // Assert: All returned todos have completed=true
  list.each(todos, fn(t) {
    should.be_true(t.completed)
  })
  
  // Assert: Contains expected completed todos
  let ids = list.map(todos, fn(t) { t.id })
  should.be_true(list.contains(ids, completed1.id))
  should.be_true(list.contains(ids, completed2.id))
  should.be_true(list.contains(ids, completed3.id))
  
  // Assert: Sorted newest-first
  assert_newest_first(todos)
  
  // Assert: Newest completed todo is first
  let assert Ok(first) = list.first(todos)
  should.equal(first.id, completed3.id)
}
