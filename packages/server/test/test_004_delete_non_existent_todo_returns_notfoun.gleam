import gleeunit
import gleeunit/should
import todo_store

pub fn main() {
  gleeunit.main()
}

// Delete with invalid ID returns NotFound
pub fn delete_nonexistent_returns_not_found_test() {
  let assert Ok(actor) = todo_store.start()
  
  let result = todo_store.delete(actor, "non-existent-uuid")
  
  should.equal(result, todo_store.NotFound)
}
