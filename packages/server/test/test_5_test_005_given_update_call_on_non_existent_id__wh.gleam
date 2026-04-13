import gleeunit
import gleeunit/should
import gleam/option.{None}
import todo_store
import shared.{Medium}

pub fn main() {
  gleeunit.main()
}

// Test: update returns Error(Nil) for non-existent ID
pub fn update_returns_null_for_nonexistent_id_test() {
  // Given: A non-existent ID
  let non_existent_id = "non-existent-id-12345"
  let update_attrs = shared.new_todo(title: "New Title", description: None, priority: Medium)

  // When: update is called with non-existent ID
  let result = todo_store.update(non_existent_id, update_attrs)

  // Then: Returns Error(Nil)
  should.be_error(result)
}
