import gleeunit
import gleeunit/should
import todo_store
import gleam/option.{None}

pub fn main() {
  gleeunit.main()
}

// Actor starts with empty state
pub fn actor_initializes_empty_test() {
  let assert Ok(actor) = todo_store.start()
  
  // List should return empty
  let todos = todo_store.list(actor)
  should.equal(todos, [])
  
  // Get any ID should return None
  let result = todo_store.get(actor, "any-id")
  should.equal(result, None)
}
