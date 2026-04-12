// Test: Empty state is hidden when todos match current filter
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

// Test: When todos exist and match filter, empty state is hidden
pub fn todos_exist_empty_state_hidden_test() {
  // Given: todos exist that match current filter
  let todos = [
    TodoItem(
      id: "todo-1",
      title: "Active task",
      description: None,
      priority: "high",
      completed: False,
      created_at: 1234567890
    ),
    TodoItem(
      id: "todo-2",
      title: "Completed task",
      description: None,
      priority: "medium",
      completed: True,
      created_at: 1234567891
    )
  ]
  
  // When: filter=all (matches all todos)
  let all_todos = todos
  let html_all = empty_states.render(all_todos, "all")
  
  // Then: empty state is hidden, todos are shown (not in empty-state div)
  test_helpers.not_contain(html_all, "No todos yet")
  test_helpers.not_contain(html_all, "No active todos")
  test_helpers.not_contain(html_all, "No completed todos")
  // Verify the container renders in non-empty state mode (typically hidden or absent)
  test_helpers.contain(html_all, "todo-list")

  // When: filter=active (matches first todo)
  let active_todos = list.filter(todos, fn(t) { !t.completed })
  let html_active = empty_states.render(active_todos, "active")

  // Then: empty state is hidden
  test_helpers.not_contain(html_active, "No active todos")
  should.equal(list.length(active_todos), 1)

  // When: filter=completed (matches second todo)
  let completed_todos = list.filter(todos, fn(t) { t.completed })
  let html_completed = empty_states.render(completed_todos, "completed")

  // Then: empty state is hidden
  test_helpers.not_contain(html_completed, "No completed todos")
  should.equal(list.length(completed_todos), 1)
}
