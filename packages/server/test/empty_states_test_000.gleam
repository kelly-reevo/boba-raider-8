// Test: Empty state when no todos exist in system
// Run with: gleam test --target javascript

import gleam/list
import gleeunit
import gleeunit/should
import todo_item.{type TodoItem, TodoItem}
import web/empty_states
import web/test_helpers

pub fn main() {
  gleeunit.main()
}

// Test: When no todos exist, display 'No todos yet. Create one above!' message
pub fn no_todos_empty_state_test() {
  // Given: empty todo list from API
  let todos: List(TodoItem) = []
  let filter = "all"
  
  // When: rendering the empty state
  let html = empty_states.render(todos, filter)
  
  // Then: display appropriate message with correct CSS class
  test_helpers.contain(html, "empty-state")
  test_helpers.contain(html, "No todos yet. Create one above!")
  test_helpers.contain(html, "<div class='empty-state'>")
  test_helpers.contain(html, "<p>")
}
