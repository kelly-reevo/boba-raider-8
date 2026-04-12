import gleeunit
import gleeunit/should
import todo_store
import gleam/option.{Some, None}
import gleam/string

pub fn main() {
  gleeunit.main()
}

// Given the actor is started, when a todo is inserted, then the todo is stored with a generated UUID
pub fn insert_todo_generates_uuid_test() {
  // Start the actor with empty state
  let assert Ok(actor) = todo_store.start()
  
  // Insert a todo
  let todo_data = todo_store.TodoData(
    title: "Buy groceries",
    description: Some("Milk, eggs, bread"),
    priority: todo_store.Medium,
    completed: False,
    created_at: "2024-01-15T10:30:00Z",
    updated_at: "2024-01-15T10:30:00Z"
  )
  let id = todo_store.insert(actor, todo_data)
  
  // Verify UUID is generated (non-empty string)
  should.be_true(string.length(id) > 0)
  
  // Verify we can retrieve it
  let assert Some(stored) = todo_store.get(actor, id)
  should.equal(stored.title, "Buy groceries")
  should.equal(stored.description, Some("Milk, eggs, bread"))
  should.equal(stored.priority, todo_store.Medium)
  should.equal(stored.completed, False)
}
