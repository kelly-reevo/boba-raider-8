import gleeunit
import gleeunit/should
import gleam/option.{None}
import gleam/list
import todo_store
import shared.{Low, Medium, High}

pub fn main() {
  gleeunit.main()
}

// Test: get_all returns all stored todos in creation order
pub fn get_all_returns_todos_in_creation_order_test() {
  // Clear store to ensure clean state
  todo_store.clear()

  // Given: 5 stored todos created in sequence
  let attrs1 = shared.new_todo(title: "Task 1", description: None, priority: Low)
  let attrs2 = shared.new_todo(title: "Task 2", description: None, priority: Medium)
  let attrs3 = shared.new_todo(title: "Task 3", description: None, priority: High)
  let attrs4 = shared.new_todo(title: "Task 4", description: None, priority: Low)
  let attrs5 = shared.new_todo(title: "Task 5", description: None, priority: Medium)
  
  let assert Ok(todo1) = todo_store.create(attrs1)
  let assert Ok(todo2) = todo_store.create(attrs2)
  let assert Ok(todo3) = todo_store.create(attrs3)
  let assert Ok(todo4) = todo_store.create(attrs4)
  let assert Ok(todo5) = todo_store.create(attrs5)
  
  // When: get_all is executed
  let result = todo_store.get_all()
  
  // Then: Returns list of 5 todos in creation order
  should.equal(list.length(result), 5)
  
  // Verify order matches creation sequence
  let ids = list.map(result, fn(t) { t.id })
  should.equal(ids, [todo1.id, todo2.id, todo3.id, todo4.id, todo5.id])
  
  // Verify titles are preserved
  let titles = list.map(result, fn(t) { t.title })
  should.equal(titles, ["Task 1", "Task 2", "Task 3", "Task 4", "Task 5"])
}
