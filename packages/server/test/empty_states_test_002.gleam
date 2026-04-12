// Test: Empty state when filtering for completed todos but none exist
// Run with: gleam test --target javascript

import gleam/list
import gleam/option.{None}
import gleeunit
import gleeunit/should
import todo_item.{type TodoItem, TodoItem}
import web/empty_states
import web/test_helpers

pub fn main() {
  gleeunit.main()
}

// Test: When filter=completed and no completed todos, show 'No completed todos'
pub fn no_completed_todos_empty_state_test() {
  // Given: todos exist but none are completed
  let todos = [
    TodoItem(
      id: "todo-1",
      title: "Active task 1",
      description: None,
      priority: "medium",
      completed: False,
      created_at: 1234567890
    ),
    TodoItem(
      id: "todo-2",
      title: "Active task 2",
      description: None,
      priority: "low",
      completed: False,
      created_at: 1234567891
    )
  ]
  let filter = "completed"
  
  // When: filtering for completed todos (none match)
  let completed_todos = list.filter(todos, fn(t) { t.completed })
  let html = empty_states.render(completed_todos, filter)
  
  // Then: display 'No completed todos' message with correct CSS class
  test_helpers.contain(html, "empty-state")
  test_helpers.contain(html, "No completed todos")
  test_helpers.contain(html, "<div class='empty-state'>")
  test_helpers.contain(html, "<p>")
  should.equal(list.length(completed_todos), 0)
}
