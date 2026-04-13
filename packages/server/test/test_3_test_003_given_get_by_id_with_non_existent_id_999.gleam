import gleeunit
import gleeunit/should
import todo_store

pub fn main() {
  gleeunit.main()
}

// Test: get_by_id returns null for non-existent ID
pub fn get_by_id_returns_null_for_nonexistent_id_test() {
  // Given: A non-existent ID '999'
  let non_existent_id = "999"
  
  // When: get_by_id is called with non-existent ID
  let result = todo_store.get_by_id(non_existent_id)
  
  // Then: Returns null (None in Gleam)
  should.be_none(result)
}
