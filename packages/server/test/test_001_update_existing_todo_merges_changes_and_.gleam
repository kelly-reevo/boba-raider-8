import gleeunit
import gleeunit/should
import todo_store
import gleam/option.{Some, None}

pub fn main() {
  gleeunit.main()
}

// Given a stored todo, when updated via ID, then the changes are merged into the stored todo
pub fn update_todo_merges_changes_test() {
  let assert Ok(actor) = todo_store.start()
  
  // Insert initial todo
  let todo_data = todo_store.TodoData(
    title: "Original title",
    description: None,
    priority: todo_store.Low,
    completed: False
  )
  let id = todo_store.insert(actor, todo_data)
  
  // Update the todo
  let changes = todo_store.TodoData(
    title: "Updated title",
    description: Some("Added description"),
    priority: todo_store.High,
    completed: True
  )
  let result = todo_store.update(actor, id, changes)
  
  // Should return Ok
  should.equal(result, todo_store.Ok)
  
  // Verify changes were merged
  let assert Some(updated) = todo_store.get(actor, id)
  should.equal(updated.title, "Updated title")
  should.equal(updated.description, Some("Added description"))
  should.equal(updated.priority, todo_store.High)
  should.equal(updated.completed, True)
}
