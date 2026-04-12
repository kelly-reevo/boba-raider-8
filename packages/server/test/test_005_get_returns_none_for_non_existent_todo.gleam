import gleeunit
import gleeunit/should
import todo_store
import gleam/option.{None}

pub fn main() {
  gleeunit.main()
}

// Get with invalid ID returns None
pub fn get_nonexistent_returns_none_test() {
  let assert Ok(actor) = todo_store.start()
  
  let result = todo_store.get(actor, "non-existent-uuid")
  
  should.equal(result, None)
}
