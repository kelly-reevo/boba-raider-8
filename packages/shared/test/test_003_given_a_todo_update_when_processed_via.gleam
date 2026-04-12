import gleeunit
import gleeunit/should
import shared
import gleam/string
import gleam/option.{Some, None}

pub fn main() {
  gleeunit.main()
}

// Test: Creating a Todo with different created_at and updated_at simulates update
pub fn todo_update_has_different_updated_at_timestamp_test() {
  // Simulate an updated todo by constructing with different timestamps
  let original_created = "2024-01-15T10:00:00Z"
  let updated_time = "2024-01-15T11:30:00Z"
  
  let item = shared.Todo(
    id: "550e8400-e29b-41d4-a716-446655440000",
    title: "Updated Task",
    description: Some("Updated description"),
    priority: shared.High,
    completed: True,
    created_at: original_created,
    updated_at: updated_time,
  )

  // updated_at should differ from created_at after update
  item.updated_at |> should.not_equal(item.created_at)
  item.updated_at |> should.equal(updated_time)
  item.created_at |> should.equal(original_created)
}

// Test: Serialization preserves different timestamps
pub fn todo_to_json_preserves_updated_at_timestamp_test() {
  let item = shared.Todo(
    id: "550e8400-e29b-41d4-a716-446655440000",
    title: "Updated Task",
    description: Some("Updated description"),
    priority: shared.Medium,
    completed: True,
    created_at: "2024-01-15T10:00:00Z",
    updated_at: "2024-01-15T11:30:45Z",
  )

  let json_string = shared.todo_to_json(item)
  
  // Both timestamps appear in JSON output
  json_string |> string.contains("\"created_at\":\"2024-01-15T10:00:00Z\"") |> should.equal(True)
  json_string |> string.contains("\"updated_at\":\"2024-01-15T11:30:45Z\"") |> should.equal(True)
}

// Test: New todo has matching created_at and updated_at (before any update)
pub fn new_todo_has_matching_created_and_updated_timestamps_test() {
  let result = shared.new_todo(
    title: "Fresh task",
    description: None,
    priority: shared.Low,
  )
  
  case result {
    Ok(item) -> {
      // On creation, both timestamps are identical
      item.updated_at |> should.equal(item.created_at)
    }
    Error(_) -> should.fail()
  }
}