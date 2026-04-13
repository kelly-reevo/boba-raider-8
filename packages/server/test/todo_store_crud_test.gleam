import gleam/list
import gleam/option.{Some, None}
import gleam/string
import gleeunit
import gleeunit/should
import app_supervisor

pub fn main() {
  gleeunit.main()
}

// Test 000: Create stores todo with generated UUID and returns it
pub fn create_generates_id_and_stores_todo_test() {
  let app = app_supervisor.start_test()

  let payload = [
    #("title", "Buy groceries"),
    #("description", "Milk and eggs"),
    #("priority", "high"),
  ]

  let result = app_supervisor.create_todo(app, payload)

  // Should return success with generated item
  let assert Ok(item) = result

  // Verify all expected fields present
  item.title |> should.equal("Buy groceries")
  item.description |> should.equal(Some("Milk and eggs"))
  item.priority |> should.equal("high")
  item.completed |> should.equal(False)

  // Verify UUID was generated
  item.id |> should.not_equal("")
  string.length(item.id) |> should.equal(36)
}

pub fn create_validates_required_title_test() {
  let app = app_supervisor.start_test()

  let payload = [
    #("description", "No title here"),
    #("priority", "low"),
  ]

  let result = app_supervisor.create_todo(app, payload)

  // Should return validation error
  let assert Error(app_supervisor.ValidationError(errors)) = result
  list.contains(errors, "title is required") |> should.be_true()
}

// Test 001: Get returns existing todo by id
pub fn get_returns_existing_todo_test() {
  let app = app_supervisor.start_test()

  // First create an item
  let create_payload = [
    #("title", "Read book"),
    #("description", "Chapter 1"),
    #("priority", "medium"),
  ]
  let assert Ok(created) = app_supervisor.create_todo(app, create_payload)
  let id = created.id

  // Now retrieve it
  let result = app_supervisor.get_todo(app, id)

  // Should return the stored item
  let assert Ok(item) = result
  item.id |> should.equal(id)
  item.title |> should.equal("Read book")
  item.description |> should.equal(Some("Chapter 1"))
  item.priority |> should.equal("medium")
  item.completed |> should.equal(False)
}

// Test 002: Get returns not_found for non-existent id
pub fn get_returns_not_found_for_missing_id_test() {
  let app = app_supervisor.start_test()

  let non_existent_id = "00000000-0000-0000-0000-000000000000"

  let result = app_supervisor.get_todo(app, non_existent_id)

  // Should return not_found error
  let assert Error(app_supervisor.NotFound) = result
}

// Test 003: Update merges changes into existing todo
pub fn update_merges_changes_into_existing_todo_test() {
  let app = app_supervisor.start_test()

  // Create initial item
  let create_payload = [
    #("title", "Original Title"),
    #("description", "Original desc"),
    #("priority", "low"),
  ]
  let assert Ok(created) = app_supervisor.create_todo(app, create_payload)
  let id = created.id

  // Update with partial changes
  let changes = [
    #("title", "Updated Title"),
    #("completed", "true"),
  ]

  let result = app_supervisor.update_todo(app, id, changes)

  // Should return updated item with merged values
  let assert Ok(updated) = result
  updated.id |> should.equal(id)
  updated.title |> should.equal("Updated Title")
  updated.description |> should.equal(Some("Original desc"))
  updated.priority |> should.equal("low")
  updated.completed |> should.equal(True)
}

pub fn update_can_clear_optional_fields_test() {
  let app = app_supervisor.start_test()

  // Create item with description
  let create_payload = [
    #("title", "With Description"),
    #("description", "This will be cleared"),
    #("priority", "medium"),
  ]
  let assert Ok(created) = app_supervisor.create_todo(app, create_payload)

  // Update to clear description
  let changes = [
    #("description", ""),
  ]

  let result = app_supervisor.update_todo(app, created.id, changes)

  let assert Ok(updated) = result
  updated.description |> should.equal(None)
}

// Test 004: Update returns not_found for non-existent id
pub fn update_returns_not_found_for_missing_id_test() {
  let app = app_supervisor.start_test()

  let non_existent_id = "00000000-0000-0000-0000-000000000000"
  let changes = [
    #("title", "New Title"),
  ]

  let result = app_supervisor.update_todo(app, non_existent_id, changes)

  // Should return not_found error
  let assert Error(app_supervisor.NotFoundUpdateError) = result
}

// Test 005: Update returns validation_error for invalid changes
pub fn update_validates_priority_field_test() {
  let app = app_supervisor.start_test()

  // Create an item first
  let create_payload = [
    #("title", "Test Item"),
  ]
  let assert Ok(created) = app_supervisor.create_todo(app, create_payload)

  // Try to update with invalid priority
  let changes = [
    #("priority", "invalid_value"),
  ]

  let result = app_supervisor.update_todo(app, created.id, changes)

  // Should return validation error
  let assert Error(app_supervisor.ValidationErrorUpdate(errors)) = result
  list.contains(errors, "priority must be low, medium, or high") |> should.be_true()
}

// Test 006: Delete removes todo from store
pub fn delete_removes_todo_from_store_test() {
  let app = app_supervisor.start_test()

  // Create an item
  let create_payload = [
    #("title", "To be deleted"),
  ]
  let assert Ok(created) = app_supervisor.create_todo(app, create_payload)
  let id = created.id

  // Verify it exists
  let assert Ok(_) = app_supervisor.get_todo(app, id)

  // Delete it
  let delete_result = app_supervisor.delete_todo(app, id)
  let assert Ok(_) = delete_result

  // Verify it's gone
  let get_result = app_supervisor.get_todo(app, id)
  let assert Error(app_supervisor.NotFound) = get_result
}

// Test 007: Delete returns not_found for non-existent id
pub fn delete_returns_not_found_for_missing_id_test() {
  let app = app_supervisor.start_test()

  let non_existent_id = "00000000-0000-0000-0000-000000000000"

  let result = app_supervisor.delete_todo(app, non_existent_id)

  // Should return not_found error
  let assert Error(app_supervisor.NotFoundDeleteError) = result
}
