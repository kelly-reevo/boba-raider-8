import gleeunit
import gleeunit/should
import shared
import todo_store

pub fn main() {
  gleeunit.main()
}

// Test: delete returns :not_found for non-existent ID
pub fn delete_returns_not_found_for_nonexistent_id_test() {
  // Given: A non-existent ID
  let non_existent_id = "does-not-exist-98765"
  
  // When: delete is called with non-existent ID
  let result = todo_store.delete(non_existent_id)
  
  // Then: Returns :not_found
  should.equal(result, Error(shared.NotFound("Todo not found")))
}
