import gleeunit/should
import gleam/erlang/process
import gleam/otp/actor
import gleam/option.{None, Some}
import gleam/list
import actors/todo_actor.{
  type Todo, type UpdateRequest, type UpdateResult, type TodoMessage,
  UpdateTodo, CreateTodo, GetTodo, Updated, NotFound, Todo, UpdateRequest,
}

// Test: Partial update applies only provided fields, retains omitted fields
pub fn update_existing_todo_partial_fields_test() {
  // Setup: Start the todo actor
  let assert Ok(actor_result) = todo_actor.start()
  let actor_ref = actor_result.data

  // Given: Create a todo to update
  let original_todo = Todo(
    id: "todo-123",
    title: "Original Title",
    description: "Original Description",
    priority: "medium",
    completed: False,
  )
  let create_client = process.new_subject()
  actor.send(actor_ref, CreateTodo(original_todo, create_client))
  let _ = process.receive(create_client, 1000) // Wait for creation

  // When: Send update message with only title and completed fields
  let updates = UpdateRequest(
    title: Some("Updated Title"),
    description: None,
    priority: None,
    completed: Some(True),
  )
  let update_client = process.new_subject()
  actor.send(actor_ref, UpdateTodo("todo-123", updates, update_client))

  // Then: Actor returns updated todo with merged fields
  let result = process.receive(update_client, 1000)

  case result {
    Ok(Updated(updated_todo)) -> {
      updated_todo.id |> should.equal("todo-123")
      updated_todo.title |> should.equal("Updated Title") // Changed
      updated_todo.description |> should.equal("Original Description") // Retained
      updated_todo.priority |> should.equal("medium") // Retained
      updated_todo.completed |> should.equal(True) // Changed
    }
    _ -> panic as "Expected Updated result with merged todo"
  }
}

// Test: Update all fields returns complete updated todo
pub fn update_existing_todo_all_fields_test() {
  let assert Ok(actor_result) = todo_actor.start()
  let actor_ref = actor_result.data

  // Given: Create a todo
  let original_todo = Todo(
    id: "todo-456",
    title: "Old Title",
    description: "Old Description",
    priority: "low",
    completed: False,
  )
  let create_client = process.new_subject()
  actor.send(actor_ref, CreateTodo(original_todo, create_client))
  let _ = process.receive(create_client, 1000)

  // When: Update all fields
  let updates = UpdateRequest(
    title: Some("New Title"),
    description: Some("New Description"),
    priority: Some("high"),
    completed: Some(True),
  )
  let update_client = process.new_subject()
  actor.send(actor_ref, UpdateTodo("todo-456", updates, update_client))

  // Then: All fields are updated
  let result = process.receive(update_client, 1000)

  case result {
    Ok(Updated(updated_todo)) -> {
      updated_todo.id |> should.equal("todo-456")
      updated_todo.title |> should.equal("New Title")
      updated_todo.description |> should.equal("New Description")
      updated_todo.priority |> should.equal("high")
      updated_todo.completed |> should.equal(True)
    }
    _ -> panic as "Expected Updated result"
  }
}

// Test: Update non-existent id returns NotFound
pub fn update_nonexistent_todo_returns_not_found_test() {
  // Setup: Start actor
  let assert Ok(actor_result) = todo_actor.start()
  let actor_ref = actor_result.data

  // Given: An id that doesn't exist
  let non_existent_id = "todo-does-not-exist"
  let updates = UpdateRequest(
    title: Some("New Title"),
    description: None,
    priority: None,
    completed: Some(True),
  )

  // When: Send update for non-existent todo
  let client = process.new_subject()
  actor.send(actor_ref, UpdateTodo(non_existent_id, updates, client))

  // Then: Actor returns NotFound
  let result = process.receive(client, 1000)

  case result {
    Ok(NotFound) -> Nil // Expected
    Ok(Updated(_)) -> panic as "Should not find non-existent todo"
    Error(_) -> panic as "Actor should respond, not timeout"
  }
}

// Test: Actor remains operational after NotFound response
pub fn actor_survives_not_found_request_test() {
  let assert Ok(actor_result) = todo_actor.start()
  let actor_ref = actor_result.data

  // First request: non-existent id
  let client1 = process.new_subject()
  actor.send(actor_ref, UpdateTodo("missing-1", UpdateRequest(None, None, None, None), client1))
  let _ = process.receive(client1, 1000)

  // Second request: non-existent id again (actor should still respond)
  let client2 = process.new_subject()
  actor.send(actor_ref, UpdateTodo("missing-2", UpdateRequest(None, None, None, None), client2))
  let result2 = process.receive(client2, 1000)

  // Then: Actor still responds correctly
  case result2 {
    Ok(NotFound) -> Nil // Actor is still operational
    _ -> panic as "Actor should remain operational after NotFound"
  }
}

// Test: Concurrent updates to same todo - all succeed, final state is consistent
pub fn concurrent_updates_last_write_wins_test() {
  // Setup: Start actor with a todo
  let assert Ok(actor_result) = todo_actor.start()
  let actor_ref = actor_result.data

  let original = Todo(
    id: "concurrent-todo",
    title: "Start",
    description: "Start Desc",
    priority: "low",
    completed: False,
  )

  // Create the todo
  let create_client = process.new_subject()
  actor.send(actor_ref, CreateTodo(original, create_client))
  let _ = process.receive(create_client, 1000)

  // When: Send multiple concurrent updates to same todo
  let update1 = UpdateRequest(Some("Update A"), None, None, Some(True))
  let update2 = UpdateRequest(Some("Update B"), None, None, Some(True))
  let update3 = UpdateRequest(Some("Update C"), None, None, Some(True))

  let client1 = process.new_subject()
  let client2 = process.new_subject()
  let client3 = process.new_subject()

  // Fire all updates concurrently (no ordering guarantee)
  actor.send(actor_ref, UpdateTodo("concurrent-todo", update1, client1))
  actor.send(actor_ref, UpdateTodo("concurrent-todo", update2, client2))
  actor.send(actor_ref, UpdateTodo("concurrent-todo", update3, client3))

  // Collect all responses
  let result1 = process.receive(client1, 1000)
  let result2 = process.receive(client2, 1000)
  let result3 = process.receive(client3, 1000)

  // Then: All updates succeeded (returned Updated, not error)
  let all_updated = list.all([result1, result2, result3], fn(r) {
    case r {
      Ok(Updated(_)) -> True
      _ -> False
    }
  })
  all_updated |> should.equal(True)

  // Verify final state is consistent (read back the todo)
  let get_client = process.new_subject()
  actor.send(actor_ref, GetTodo("concurrent-todo", get_client))
  let final_result = process.receive(get_client, 1000)

  case final_result {
    Ok(Some(final_todo)) -> {
      // Title should be one of the updates (last-write-wins)
      let valid_titles = ["Update A", "Update B", "Update C"]
      should.be_true(list.contains(valid_titles, final_todo.title))

      // All updates set completed=True, so should be true
      final_todo.completed |> should.equal(True)

      // Unchanged fields preserved
      final_todo.description |> should.equal("Start Desc")
    }
    _ -> panic as "Should retrieve final consistent state"
  }
}

// Test: Concurrent partial updates touching different fields - no corruption
pub fn concurrent_partial_updates_no_corruption_test() {
  let assert Ok(actor_result) = todo_actor.start()
  let actor_ref = actor_result.data

  let original = Todo(
    id: "mixed-todo",
    title: "Title",
    description: "Description",
    priority: "low",
    completed: False,
  )

  let create_client = process.new_subject()
  actor.send(actor_ref, CreateTodo(original, create_client))
  let _ = process.receive(create_client, 1000)

  // Concurrent partial updates touching different fields
  let update_title = UpdateRequest(Some("New Title"), None, None, None)
  let update_priority = UpdateRequest(None, None, Some("high"), None)
  let update_completed = UpdateRequest(None, None, None, Some(True))

  let client1 = process.new_subject()
  let client2 = process.new_subject()
  let client3 = process.new_subject()

  actor.send(actor_ref, UpdateTodo("mixed-todo", update_title, client1))
  actor.send(actor_ref, UpdateTodo("mixed-todo", update_priority, client2))
  actor.send(actor_ref, UpdateTodo("mixed-todo", update_completed, client3))

  // All should succeed
  let r1 = process.receive(client1, 1000)
  let r2 = process.receive(client2, 1000)
  let r3 = process.receive(client3, 1000)

  // Verify no crashes
  should.be_ok(r1)
  should.be_ok(r2)
  should.be_ok(r3)

  // Final state: last write for each field wins
  let get_client = process.new_subject()
  actor.send(actor_ref, GetTodo("mixed-todo", get_client))
  let final = process.receive(get_client, 1000)

  case final {
    Ok(Some(item)) -> {
      // Each field should have a valid value (no corruption)
      item.title |> should.equal("New Title") // Only one update touched title
      item.priority |> should.equal("high") // Only one update touched priority
      item.completed |> should.equal(True) // Only one update touched completed
      item.description |> should.equal("Description") // Never updated
    }
    _ -> panic as "Final state should be consistent"
  }
}

// Test: Empty update (all None) returns original todo unchanged
pub fn empty_update_returns_unchanged_test() {
  let assert Ok(actor_result) = todo_actor.start()
  let actor_ref = actor_result.data

  let original = Todo(
    id: "empty-test",
    title: "Original",
    description: "Original Desc",
    priority: "medium",
    completed: False,
  )

  let create_client = process.new_subject()
  actor.send(actor_ref, CreateTodo(original, create_client))
  let _ = process.receive(create_client, 1000)

  // Send empty update (all fields None)
  let empty_updates = UpdateRequest(None, None, None, None)
  let client = process.new_subject()
  actor.send(actor_ref, UpdateTodo("empty-test", empty_updates, client))

  let result = process.receive(client, 1000)

  // Then: Returns original unchanged
  case result {
    Ok(Updated(item)) -> {
      item.title |> should.equal("Original")
      item.description |> should.equal("Original Desc")
      item.priority |> should.equal("medium")
      item.completed |> should.equal(False)
    }
    _ -> panic as "Empty update should return unchanged todo"
  }
}

// Test: Single field updates work correctly
pub fn single_field_updates_test() {
  let assert Ok(actor_result) = todo_actor.start()
  let actor_ref = actor_result.data

  let original = Todo(
    id: "single-test",
    title: "Title",
    description: "Desc",
    priority: "low",
    completed: False,
  )

  let create_client = process.new_subject()
  actor.send(actor_ref, CreateTodo(original, create_client))
  let _ = process.receive(create_client, 1000)

  // Update only title
  let title_only = UpdateRequest(Some("New Title"), None, None, None)
  let client1 = process.new_subject()
  actor.send(actor_ref, UpdateTodo("single-test", title_only, client1))

  case process.receive(client1, 1000) {
    Ok(Updated(item)) -> {
      item.title |> should.equal("New Title")
      item.description |> should.equal("Desc") // Unchanged
      item.priority |> should.equal("low") // Unchanged
      item.completed |> should.equal(False) // Unchanged
    }
    _ -> panic as "Single field update should work"
  }
}

// Test: Update with empty string title is accepted (boundary case)
pub fn update_with_empty_string_accepted_test() {
  let assert Ok(actor_result) = todo_actor.start()
  let actor_ref = actor_result.data

  let original = Todo(
    id: "empty-string-test",
    title: "Valid Title",
    description: "Desc",
    priority: "medium",
    completed: False,
  )

  let create_client = process.new_subject()
  actor.send(actor_ref, CreateTodo(original, create_client))
  let _ = process.receive(create_client, 1000)

  // Update with empty string (actor accepts it, validation is external)
  let empty_title = UpdateRequest(Some(""), None, None, None)
  let client = process.new_subject()
  actor.send(actor_ref, UpdateTodo("empty-string-test", empty_title, client))

  let result = process.receive(client, 1000)

  // Actor's job is to store what it's given
  case result {
    Ok(Updated(item)) -> {
      item.title |> should.equal("")
      item.description |> should.equal("Desc") // Other fields unchanged
    }
    _ -> panic as "Actor should accept empty string as valid update"
  }
}
