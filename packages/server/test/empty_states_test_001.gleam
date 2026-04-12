// Test: Empty state when filtering for active todos but all are completed
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

// Test: When filter=active and all todos completed, show 'No active todos'
pub fn no_active_todos_empty_state_test() {
  // Given: todos exist but all are completed
  let todos = [
    TodoItem(
      id: "todo-1",
      title: "Completed task",
      description: None,
      priority: "medium",
      completed: True,
      created_at: 1234567890
    ),
    TodoItem(
      id: "todo-2",
      title: "Another completed",
      description: None,
      priority: "high",
      completed: True,
      created_at: 1234567891
    )
  ]
  let filter = "active"
  
  // When: filtering for active todos (none match)
  let active_todos = list.filter(todos, fn(t) { !t.completed })
  let html = empty_states.render(active_todos, filter)
  
  // Then: display 'No active todos' message with correct CSS class
  test_helpers.contain(html, "empty-state")
  test_helpers.contain(html, "No active todos")
  test_helpers.contain(html, "<div class='empty-state'>")
  test_helpers.contain(html, "<p>")
  should.equal(list.length(active_todos), 0)
}
