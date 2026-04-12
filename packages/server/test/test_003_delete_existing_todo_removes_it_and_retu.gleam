import gleeunit
import gleeunit/should
import todo_store
import gleam/option.{Some, None}

pub fn main() {
  gleeunit.main()
}

// Given a stored todo, when deleted via ID, then the todo is removed from storage
pub fn delete_todo_removes_it_test() {
  let assert Ok(actor) = todo_store.start()
  
  // Insert a todo
  let todo_data = todo_store.TodoData(
    title: "To be deleted",
    description: Some("Delete me"),
    priority: todo_store.Medium,
    completed: False
  )
  let id = todo_store.insert(actor, todo_data)
  
  // Verify it exists
  let assert Some(_) = todo_store.get(actor, id)
  
  // Delete it
  let result = todo_store.delete(actor, id)
  should.equal(result, todo_store.Ok)
  
  // Verify it's gone
  let not_found = todo_store.get(actor, id)
  should.equal(not_found, None)
}
