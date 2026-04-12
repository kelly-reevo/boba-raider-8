import gleeunit
import gleeunit/should
import todo_store
import gleam/option.{Some, None}

pub fn main() {
  gleeunit.main()
}

// Update with invalid ID returns NotFound
pub fn update_nonexistent_returns_not_found_test() {
  let assert Ok(actor) = todo_store.start()
  
  let changes = todo_store.TodoData(
    title: "Updated title",
    description: None,
    priority: todo_store.Medium,
    completed: True,
    created_at: "2024-01-15T10:30:00Z",
    updated_at: "2024-01-15T10:30:00Z"
  )
  let result = todo_store.update(actor, "non-existent-uuid", changes)
  
  should.equal(result, todo_store.NotFound)
}
