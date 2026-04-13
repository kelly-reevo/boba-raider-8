import gleeunit
import gleeunit/should
import gleam/option.{None, Some}
import gleam/list
import todo_actor
import models/todo_item.{Low, Medium, High}

pub fn main() {
  gleeunit.main()
}

// Test: Partial update applies only provided fields, retains omitted fields
pub fn update_existing_todo_partial_fields_test() {
  // Setup: Start the todo actor
  let assert Ok(actor_ref) = todo_actor.start()

  // Given: Create a todo to update
  let assert Ok(original_todo) = todo_actor.create(actor_ref, "Original Title", "Original Description", "medium")

  // When: Update with partial fields
  let assert Ok(updated_todo) = todo_actor.update(
    actor_ref,
    original_todo.id,
    Some("Updated Title"),
    None,
    None,
    Some(True),
  )

  // Then: Returns updated todo with merged fields
  should.equal(updated_todo.id, original_todo.id)
  should.equal(updated_todo.title, "Updated Title") // Changed
  should.equal(updated_todo.description, Some("Original Description")) // Retained
  should.equal(updated_todo.priority, Medium) // Retained
  should.equal(updated_todo.completed, True) // Changed
}

// Test: Update all fields returns complete updated todo
pub fn update_existing_todo_all_fields_test() {
  let assert Ok(actor_ref) = todo_actor.start()

  // Given: Create a todo
  let assert Ok(original) = todo_actor.create(actor_ref, "Old Title", "Old Description", "low")

  // When: Update all fields
  let assert Ok(updated) = todo_actor.update(
    actor_ref,
    original.id,
    Some("New Title"),
    Some("New Description"),
    Some("high"),
    Some(True),
  )

  // Then: All fields are updated
  should.equal(updated.title, "New Title")
  should.equal(updated.description, Some("New Description"))
  should.equal(updated.priority, High)
  should.equal(updated.completed, True)
}

// Test: Update non-existent id returns not_found error
pub fn update_nonexistent_todo_returns_not_found_test() {
  // Setup: Start actor
  let assert Ok(actor_ref) = todo_actor.start()

  // Given: An id that doesn't exist
  let non_existent_id = "todo-does-not-exist"

  // When: Update non-existent todo
  let result = todo_actor.update(
    actor_ref,
    non_existent_id,
    Some("New Title"),
    None,
    None,
    Some(True),
  )

  // Then: Returns not_found error
  should.be_error(result)
  let assert Error(err) = result
  should.equal(err, "not_found")
}

// Test: Actor remains operational after not_found response
pub fn actor_survives_not_found_request_test() {
  let assert Ok(actor_ref) = todo_actor.start()

  // First request: non-existent id
  let _ = todo_actor.update(actor_ref, "missing-1", None, None, None, None)

  // Second request: non-existent id again (actor should still respond)
  let result2 = todo_actor.update(actor_ref, "missing-2", None, None, None, None)

  // Then: Actor still responds correctly
  should.be_error(result2)
}

// Test: Concurrent updates to same todo - all succeed, final state is consistent
pub fn concurrent_updates_last_write_wins_test() {
  // Setup: Start actor with a todo
  let assert Ok(actor_ref) = todo_actor.start()
  let assert Ok(original) = todo_actor.create(actor_ref, "Start", "Start Desc", "low")

  // When: Send multiple concurrent updates to same todo
  let r1 = todo_actor.update(actor_ref, original.id, Some("Update A"), None, None, Some(True))
  let r2 = todo_actor.update(actor_ref, original.id, Some("Update B"), None, None, Some(True))
  let r3 = todo_actor.update(actor_ref, original.id, Some("Update C"), None, None, Some(True))

  // Then: All updates succeeded
  should.be_ok(r1)
  should.be_ok(r2)
  should.be_ok(r3)

  // Verify final state is consistent (read back the todo)
  let assert Ok(final_todo) = todo_actor.read(actor_ref, original.id)

  // Title should be one of the updates (last-write-wins)
  let valid_titles = ["Update A", "Update B", "Update C"]
  should.be_true(list.contains(valid_titles, final_todo.title))

  // All updates set completed=True, so should be true
  should.equal(final_todo.completed, True)

  // Unchanged fields preserved
  should.equal(final_todo.description, Some("Start Desc"))
}

// Test: Concurrent partial updates touching different fields - no corruption
pub fn concurrent_partial_updates_no_corruption_test() {
  let assert Ok(actor_ref) = todo_actor.start()
  let assert Ok(original) = todo_actor.create(actor_ref, "Title", "Description", "low")

  // Concurrent partial updates touching different fields
  let r1 = todo_actor.update(actor_ref, original.id, Some("New Title"), None, None, None)
  let r2 = todo_actor.update(actor_ref, original.id, None, None, Some("high"), None)
  let r3 = todo_actor.update(actor_ref, original.id, None, None, None, Some(True))

  // All should succeed
  should.be_ok(r1)
  should.be_ok(r2)
  should.be_ok(r3)

  // Verify final state is consistent
  let assert Ok(final) = todo_actor.read(actor_ref, original.id)

  // Each field should have a valid value (no corruption)
  should.equal(final.title, "New Title") // Only one update touched title
  should.equal(final.priority, High) // Only one update touched priority
  should.equal(final.completed, True) // Only one update touched completed
  should.equal(final.description, Some("Description")) // Never updated
}

// Test: Empty update (all None) returns original todo unchanged
pub fn empty_update_returns_unchanged_test() {
  let assert Ok(actor_ref) = todo_actor.start()
  let assert Ok(original) = todo_actor.create(actor_ref, "Original", "Original Desc", "medium")

  // Send empty update (all fields None)
  let assert Ok(updated) = todo_actor.update(actor_ref, original.id, None, None, None, None)

  // Then: Returns original unchanged
  should.equal(updated.title, "Original")
  should.equal(updated.description, Some("Original Desc"))
  should.equal(updated.priority, Medium)
  should.equal(updated.completed, False)
}

// Test: Single field updates work correctly
pub fn single_field_updates_test() {
  let assert Ok(actor_ref) = todo_actor.start()
  let assert Ok(original) = todo_actor.create(actor_ref, "Title", "Desc", "low")

  // Update only title
  let assert Ok(updated) = todo_actor.update(actor_ref, original.id, Some("New Title"), None, None, None)

  should.equal(updated.title, "New Title")
  should.equal(updated.description, Some("Desc")) // Unchanged
  should.equal(updated.priority, Low) // Unchanged
  should.equal(updated.completed, False) // Unchanged
}

// Test: Update with empty string title is accepted (boundary case)
pub fn update_with_empty_string_accepted_test() {
  let assert Ok(actor_ref) = todo_actor.start()
  let assert Ok(original) = todo_actor.create(actor_ref, "Valid Title", "Desc", "medium")

  // Update with empty string (actor accepts it, validation is external)
  let assert Ok(updated) = todo_actor.update(actor_ref, original.id, Some(""), None, None, None)

  // Actor's job is to store what it's given
  should.equal(updated.title, "")
  should.equal(updated.description, Some("Desc")) // Other fields unchanged
}

fn list_contains(list: List(a), item: a) -> Bool {
  case list {
    [] -> False
    [first, ..rest] -> first == item || list_contains(rest, item)
  }
}
