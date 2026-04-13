import gleeunit
import gleeunit/should
import gleam/option.{None}
import gleam/list
import todo_store
import shared.{Medium}

pub fn main() {
  gleeunit.main()
}

// Test: delete returns :ok and removes todo from storage
pub fn delete_returns_ok_and_removes_todo_test() {
  // Given: An existing todo
  let attrs = shared.new_todo_attrs(title: "Delete Me", description: None, priority: Medium)
  let assert Ok(created) = todo_store.create(attrs)
  let target_id = created.id
  
  // Verify it exists before deletion
  should.be_some(todo_store.get_by_id(target_id))
  
  // When: delete is called on existing ID
  let result = todo_store.delete(target_id)
  
  // Then: Returns :ok
  should.equal(result, Ok(Nil))
  
  // And: Todo is removed from storage
  let after_delete = todo_store.get_by_id(target_id)
  should.be_none(after_delete)
  
  // Verify it's not in get_all either
  let all = todo_store.get_all()
  let found = list.any(all, fn(t) { t.id == target_id })
  should.be_false(found)
}
