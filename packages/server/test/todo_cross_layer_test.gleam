import gleeunit
import gleeunit/should
import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/option.{None, Some}
import gleam/otp/actor
import gleam/string
import shared.{type AppError, type Priority, type Todo, High, Low, Medium}
import todo_actor.{
  type TodoMsg, CreateTodo, DeleteTodo, GetAllTodos, GetTodoById, UpdateTodo,
}
import todo_validation

pub fn main() {
  gleeunit.main()
}

// =============================================================================
// CROSS-LAYER TEST: todo-validation + shared types
// =============================================================================

/// Bridge: Validation accepts Priority type from shared package and returns
/// validation result that feeds into Todo creation
pub fn validation_returns_valid_priority_test() {
  let result = todo_validation.validate_todo_input("Task title", None, "high")

  case result {
    Ok(todo_input) -> {
      todo_input.title |> should.equal("Task title")
      todo_input.priority |> should.equal(High)
    }
    Error(_) -> should.fail()
  }
}

/// Bridge: Validation correctly rejects invalid priority strings that would
/// fail when converted to shared.Priority
pub fn validation_rejects_invalid_priority_test() {
  let result = todo_validation.validate_todo_input("Task", None, "urgent")

  let assert Error(errors) = result
  list.any(errors, fn(e) { string.contains(e, "priority") })
  |> should.be_true
}

/// Bridge: Validation produces error format compatible with shared.AppError
/// InvalidInput variant for API error responses
pub fn validation_errors_compatible_with_app_error_test() {
  let result = todo_validation.validate_todo_input("", None, "invalid")

  let assert Error(errors) = result

  // These errors can be wrapped in shared.InvalidInput for API responses
  let app_error = shared.InvalidInput(errors)
  let error_json = shared.error_to_json(app_error)

  // Verify JSON output contains expected structure
  error_json |> string.contains("invalid_input") |> should.be_true
}

/// Bridge: Validated todo input can be passed to actor for creation
pub fn validation_output_feeds_actor_create_test() {
  // Start a fresh todo actor
  let assert Ok(todo_subject) = todo_actor.start()

  // Validate input (simulating API request validation)
  let assert Ok(valid_input) =
    todo_validation.validate_todo_input("Buy milk", Some("2% organic"), "medium")

  // Pass validated data to actor
  let created_todo =
    todo_actor.create_todo(
      todo_subject,
      valid_input.title,
      valid_input.description,
      valid_input.priority,
    )

  // Verify the created todo matches validated input
  created_todo.title |> should.equal("Buy milk")
  created_todo.priority |> should.equal(Medium)
  created_todo.description |> should.equal(Some("2% organic"))
  created_todo.completed |> should.be_false
}

// =============================================================================
// CROSS-LAYER TEST: todo-actor + shared types
// =============================================================================

/// Bridge: Actor create returns Todo type from shared package
pub fn actor_create_returns_shared_todo_type_test() {
  let assert Ok(todo_subject) = todo_actor.start()

  let created = todo_actor.create_todo(todo_subject, "Test task", None, High)

  // Verify it's the shared.Todo type with all expected fields
  created.id |> string.length |> should.equal(36) // UUID length
  created.title |> should.equal("Test task")
  created.description |> should.equal(None)
  created.priority |> should.equal(High)
  created.completed |> should.be_false
}

/// Bridge: Actor stores and returns List(Todo) from shared package
pub fn actor_get_all_returns_list_of_shared_todos_test() {
  let assert Ok(todo_subject) = todo_actor.start()

  // Create multiple todos
  let _ = todo_actor.create_todo(todo_subject, "First", None, Low)
  let _ = todo_actor.create_todo(todo_subject, "Second", Some("desc"), Medium)

  // Get all returns List(Todo) from shared
  let all = todo_actor.get_all_todos(todo_subject)

  list.length(all) |> should.equal(2)

  // Verify each is shared.Todo type
  let first = list.first(all) |> should.be_ok
  first.title |> should.equal("First")
  first.priority |> should.equal(Low)
}

/// Bridge: Actor get by ID returns Result(Todo, AppError) from shared
pub fn actor_get_by_id_returns_shared_result_type_test() {
  let assert Ok(todo_subject) = todo_actor.start()

  let created = todo_actor.create_todo(todo_subject, "Find me", None, High)

  // Get existing returns Ok(Todo)
  let result = todo_actor.get_todo(todo_subject, created.id)
  case result {
    Ok(t) -> t.id |> should.equal(created.id)
    Error(_) -> should.fail()
  }

  // Get non-existent returns Error(NotFound)
  let not_found = todo_actor.get_todo(todo_subject, "non-existent-id")
  case not_found {
    Error(shared.NotFound) -> True |> should.be_true
    _ -> should.fail()
  }
}

/// Bridge: Actor update returns Result(Todo, AppError) compatible with shared types
pub fn actor_update_returns_shared_result_type_test() {
  let assert Ok(todo_subject) = todo_actor.start()

  let created = todo_actor.create_todo(todo_subject, "Original", None, Low)

  // Update with valid patch
  let patch = todo_validation.TodoPatch(title: Some("Updated"), completed: None)
  let result = todo_actor.update_todo(todo_subject, created.id, patch)

  case result {
    Ok(updated) -> {
      updated.id |> should.equal(created.id)
      updated.title |> should.equal("Updated")
      updated.priority |> should.equal(Low) // Unchanged
    }
    Error(_) -> should.fail()
  }
}

/// Bridge: Actor update returns NotFound AppError for missing todo
pub fn actor_update_not_found_returns_shared_error_test() {
  let assert Ok(todo_subject) = todo_actor.start()

  let patch = todo_validation.TodoPatch(title: Some("New title"), completed: None)
  let result = todo_actor.update_todo(todo_subject, "missing-id", patch)

  case result {
    Error(shared.NotFound) -> True |> should.be_true
    _ -> should.fail()
  }
}

/// Bridge: Actor delete returns Result(Bool, AppError) with NotFound error
pub fn actor_delete_returns_shared_result_type_test() {
  let assert Ok(todo_subject) = todo_actor.start()

  let created = todo_actor.create_todo(todo_subject, "To delete", None, Medium)

  // Delete existing returns Ok(True)
  let result = todo_actor.delete_todo(todo_subject, created.id)
  case result {
    Ok(True) -> True |> should.be_true
    _ -> should.fail()
  }

  // Delete again returns Error(NotFound)
  let not_found = todo_actor.delete_todo(todo_subject, created.id)
  case not_found {
    Error(shared.NotFound) -> True |> should.be_true
    _ -> should.fail()
  }
}

/// Bridge: Actor state persists across multiple operations (in-memory)
pub fn actor_state_persists_across_operations_test() {
  let assert Ok(todo_subject) = todo_actor.start()

  // Create 3 todos
  let t1 = todo_actor.create_todo(todo_subject, "One", None, Low)
  let t2 = todo_actor.create_todo(todo_subject, "Two", Some("desc"), Medium)
  let t3 = todo_actor.create_todo(todo_subject, "Three", None, High)

  // Update one
  let patch = todo_validation.TodoPatch(title: None, completed: Some(True))
  let assert Ok(updated) = todo_actor.update_todo(todo_subject, t2.id, patch)
  updated.completed |> should.be_true

  // Delete one
  let assert Ok(True) = todo_actor.delete_todo(todo_subject, t1.id)

  // Verify remaining state
  let all = todo_actor.get_all_todos(todo_subject)
  list.length(all) |> should.equal(2)

  // t1 deleted, t2 updated (completed), t3 unchanged
  list.any(all, fn(t) { t.id == t2.id && t.completed })
  |> should.be_true

  list.any(all, fn(t) { t.id == t3.id && !t.completed })
  |> should.be_true

  list.any(all, fn(t) { t.id == t1.id }) |> should.be_false
}

// =============================================================================
// CROSS-LAYER TEST: Full data flow (validation -> actor -> shared types)
// =============================================================================

/// Bridge: Complete flow from raw input through validation to actor storage
pub fn full_create_flow_validation_to_actor_test() {
  let assert Ok(todo_subject) = todo_actor.start()

  // Raw API input
  let raw_title = "Complete task"
  let raw_desc = "Do it well"
  let raw_priority = "high"

  // Layer 1: Validation (returns structured input)
  let assert Ok(validated) =
    todo_validation.validate_todo_input(raw_title, Some(raw_desc), raw_priority)

  // Layer 2: Actor creates Todo (returns shared.Todo)
  let created =
    todo_actor.create_todo(
      todo_subject,
      validated.title,
      validated.description,
      validated.priority,
    )

  // Verify shared.Todo structure
  created.title |> should.equal("Complete task")
  created.description |> should.equal(Some("Do it well"))
  created.priority |> should.equal(High)
}

/// Bridge: Full update flow with validation patch feeding actor update
pub fn full_update_flow_validation_patch_to_actor_test() {
  let assert Ok(todo_subject) = todo_actor.start()

  // Create initial todo
  let assert Ok(validated) =
    todo_validation.validate_todo_input("Original", None, "low")
  let created =
    todo_actor.create_todo(
      todo_subject,
      validated.title,
      validated.description,
      validated.priority,
    )

  // Validate update patch
  let update_patch = todo_validation.TodoPatch(
    title: Some("Updated title"),
    completed: Some(True),
  )

  // Actor applies patch, returns Result(shared.Todo, shared.AppError)
  let assert Ok(updated) =
    todo_actor.update_todo(todo_subject, created.id, update_patch)

  updated.title |> should.equal("Updated title")
  updated.completed |> should.be_true
  updated.priority |> should.equal(Low) // Unchanged from original
}

/// Bridge: Error flow - validation errors can be converted to shared.AppError
pub fn validation_errors_convert_to_shared_app_error_test() {
  let result = todo_validation.validate_todo_input("", Some("x"), "invalid")

  let assert Error(errors) = result

  // Convert to shared error type for API response
  let app_error: AppError = shared.InvalidInput(errors)

  // Verify error message generation
  let msg = shared.error_message(app_error)
  msg |> string.contains("Invalid input") |> should.be_true

  // Verify JSON serialization
  let json = shared.error_to_json(app_error)
  json |> string.contains("invalid_input") |> should.be_true
  json |> string.contains("details") |> should.be_true
}

// =============================================================================
// CROSS-LAYER TEST: Priority encoding round-trip through actor
// =============================================================================

/// Bridge: Priority values survive round-trip through actor storage
pub fn priority_round_trip_through_actor_test() {
  let assert Ok(todo_subject) = todo_actor.start()

  // Create with each priority level
  let low_todo = todo_actor.create_todo(todo_subject, "Low", None, Low)
  let med_todo = todo_actor.create_todo(todo_subject, "Medium", None, Medium)
  let high_todo = todo_actor.create_todo(todo_subject, "High", None, High)

  // Retrieve and verify priorities preserved
  let assert Ok(fetched_low) = todo_actor.get_todo(todo_subject, low_todo.id)
  let assert Ok(fetched_med) = todo_actor.get_todo(todo_subject, med_todo.id)
  let assert Ok(fetched_high) = todo_actor.get_todo(todo_subject, high_todo.id)

  fetched_low.priority |> should.equal(Low)
  fetched_med.priority |> should.equal(Medium)
  fetched_high.priority |> should.equal(High)
}

// =============================================================================
// CROSS-LAYER TEST: Actor message protocol with shared types
// =============================================================================

/// Bridge: Actor message types use shared.Todo and shared.AppError
pub fn actor_message_types_use_shared_types_test() {
  // This test verifies the message protocol contracts compile correctly
  // The type signatures bridge validation input -> actor messages

  // CreateTodo carries validated fields, returns Todo
  let create_msg: TodoMsg =
    CreateTodo(
      title: "Test",
      description: None,
      priority: High,
      reply_with: process.new_subject(),
    )

  // UpdateTodo carries TodoPatch, returns Result(Todo, AppError)
  let patch = todo_validation.TodoPatch(title: None, completed: Some(True))
  let update_msg: TodoMsg =
    UpdateTodo(id: "123", changes: patch, reply_with: process.new_subject())

  // GetTodoById returns Result(Todo, AppError)
  let get_msg: TodoMsg = GetTodoById(id: "123", reply_with: process.new_subject())

  // DeleteTodo returns Result(Bool, AppError)
  let delete_msg: TodoMsg = DeleteTodo(id: "123", reply_with: process.new_subject())

  // All messages compile with correct types - test passes if this compiles
  True |> should.be_true
}
