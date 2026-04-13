import gleeunit
import gleeunit/should
import gleam/option.{None, Some}
import todo_store
import shared.{Medium}

pub fn main() {
  gleeunit.main()
}

// Test: get_by_id returns matching todo for existing ID
pub fn get_by_id_returns_todo_for_existing_id_test() {
  // Given: An existing todo in storage
  let attrs = shared.new_todo_attrs(title: "Find Me", description: None, priority: Medium)
  let assert Ok(created) = todo_store.create(attrs)
  let target_id = created.id
  
  // When: get_by_id is called with the existing ID
  let result = todo_store.get_by_id(target_id)
  
  // Then: Returns the matching todo
  should.be_some(result)
  let assert Some(found) = result
  should.equal(found.id, target_id)
  should.equal(found.title, "Find Me")
}
