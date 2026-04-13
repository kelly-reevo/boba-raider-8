import gleam/string
import gleeunit
import gleeunit/should
import gleam/option.{Some}
import models/todo_item.{Low, Medium, High}
import todo_actor

// Boundary contract: Input: id: string
// Output: {id, title, description, priority, completed, created_at} | null/not_found

pub fn main() {
  gleeunit.main()
}

// Test that reading an existing todo returns the complete todo record
pub fn read_existing_todo_returns_todo_test() {
  // Arrange: Start actor and create a todo
  let assert Ok(actor_pid) = todo_actor.start()
  let title = "Test Todo"
  let description = "Test Description"
  let priority = "high"

  // Create a todo first (via boundary operation)
  let create_result = todo_actor.create(actor_pid, title, description, priority)
  let assert Ok(created_todo) = create_result
  let existing_id = created_todo.id

  // Act: Send read message with existing id
  let read_result = todo_actor.read(actor_pid, existing_id)

  // Assert: Returns complete todo record matching boundary contract
  let assert Ok(found_todo) = read_result
  should.equal(found_todo.id, existing_id)
  should.equal(found_todo.title, title)
  should.equal(found_todo.description, Some(description))
  should.equal(found_todo.priority, High)
  should.equal(found_todo.completed, False)
  should.be_true(found_todo.created_at > 0)

  // Cleanup
  todo_actor.shutdown(actor_pid)
}

// Test that reading a non-existent todo returns not-found indicator
pub fn read_nonexistent_todo_returns_not_found_test() {
  // Arrange: Start actor with empty state
  let assert Ok(actor_pid) = todo_actor.start()
  let non_existent_id = "non-existent-id-12345"

  // Act: Send read message with non-existent id
  let read_result = todo_actor.read(actor_pid, non_existent_id)

  // Assert: Returns not-found indicator (null or explicit error)
  should.be_error(read_result)
  // Error should indicate not-found specifically
  let assert Error(error) = read_result
  should.equal(error, "not_found")

  // Cleanup
  todo_actor.shutdown(actor_pid)
}

// Test boundary contract: id input must be string type
pub fn read_with_empty_string_id_returns_not_found_test() {
  // Arrange: Start actor
  let assert Ok(actor_pid) = todo_actor.start()
  let empty_id = ""

  // Act: Send read with empty string id
  let read_result = todo_actor.read(actor_pid, empty_id)

  // Assert: Empty string is treated as non-existent
  should.be_error(read_result)

  // Cleanup
  todo_actor.shutdown(actor_pid)
}

// Test boundary contract: output fields match expected schema
pub fn read_returns_todo_with_required_schema_fields_test() {
  // Arrange: Start actor and create todo
  let assert Ok(actor_pid) = todo_actor.start()
  let assert Ok(created) = todo_actor.create(actor_pid, "Schema Test", "", "medium")

  // Act: Read the todo
  let assert Ok(found_todo) = todo_actor.read(actor_pid, created.id)

  // Assert: All boundary contract fields are present and correctly typed
  // Verify id is non-empty string
  should.be_true(string.length(found_todo.id) > 0)
  // Verify title is correct
  should.equal(found_todo.title, "Schema Test")
  // Verify description is empty string (stored as Some(""))
  should.equal(found_todo.description, Some(""))
  // Verify priority is valid (Medium enum value)
  should.equal(found_todo.priority, Medium)
  // Verify completed is a boolean (False for new todos)
  should.be_false(found_todo.completed)
  // Verify created_at is non-empty string
  should.be_true(found_todo.created_at > 0)

  // Cleanup
  todo_actor.shutdown(actor_pid)
}
