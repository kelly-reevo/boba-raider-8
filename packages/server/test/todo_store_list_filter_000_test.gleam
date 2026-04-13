// Behavioral test: list_all filter=all returns all todos sorted newest-first
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

// ACCEPTANCE CRITERION: Given todos with mixed completion status, when list with filter=all, then all todos returned in newest-first order
// Test type: integration (tests store public interface boundary contract)
pub fn list_all_filter_all_returns_all_todos_test() {
  // Setup: Start store and create mix of completed and incomplete todos
  let assert Ok(store) = todo_store.start()
  let assert Ok(todo1) = todo_store.create_todo(store, "First Todo", "Description 1")
  let assert Ok(todo2) = todo_store.create_todo(store, "Second Todo", "Description 2")
  let completed_todo = create_completed_todo(store, "Completed Todo", "Done")
  
  // Action: List all todos with filter=all
  let result = todo_store.list_all(store, "all")
  
  // Assert: Returns Ok with all 3 todos
  let assert Ok(todos) = result
  should.equal(list.length(todos), 3)
  
  // Assert: Contains both completed and incomplete todos
  let has_completed = list.any(todos, fn(t) { t.completed })
  let has_incomplete = list.any(todos, fn(t) { !t.completed })
  should.be_true(has_completed)
  should.be_true(has_incomplete)
  
  // Assert: Sorted newest-first by created_at
  assert_newest_first(todos)
  
  // Assert: Newest todo (completed) is first
  let assert Ok(first) = list.first(todos)
  should.equal(first.id, completed_todo.id)
}
