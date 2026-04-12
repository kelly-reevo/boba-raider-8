import gleeunit
import gleeunit/should
import todo_store

pub fn main() {
  gleeunit.main()
}

// List on empty actor returns empty list
pub fn list_empty_returns_empty_test() {
  let assert Ok(actor) = todo_store.start()
  
  let todos = todo_store.list(actor)
  
  should.equal(todos, [])
}
