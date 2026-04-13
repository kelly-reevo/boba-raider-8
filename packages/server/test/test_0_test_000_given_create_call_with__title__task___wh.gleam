import gleeunit
import gleeunit/should
import gleam/option.{None}
import gleam/string
import todo_store
import shared.{Medium}

pub fn main() {
  gleeunit.main()
}

// Test: create returns todo with generated id and created_at timestamp
pub fn create_generates_id_and_timestamp_test() {
  // Given: A create call with title 'Task'
  let attrs = shared.new_todo_attrs(title: "Task", description: None, priority: Medium)

  // When: Executed through the storage interface
  let result = todo_store.create(attrs)
  
  // Then: Returns todo with generated id and created_at timestamp
  case result {
    Ok(t) -> {
      // Verify ID is generated (non-empty string)
      should.be_true(string.length(t.id) > 0)
      // Verify created_at is present (non-empty string)
      should.be_true(string.length(t.created_at) > 0)
      // Verify title matches input
      should.equal(t.title, "Task")
    }
    Error(_) -> should.fail()
  }
}
