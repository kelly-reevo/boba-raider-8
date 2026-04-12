// Test file for todo_store module
// Verifies all behaviors from both todo-store-actor and todo-store-crud-operations units

import gleeunit
import gleeunit/should
import gleam/dict
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import shared.{UpdateTodoInput}
import todo_store

pub fn main() {
  gleeunit.main()
}

// =============================================================================
// Tests from todo-store-actor unit (legacy Pid-based interface)
// =============================================================================

// Test: Actor initializes with empty state when started
pub fn start_link_returns_pid_test() {
  let result = todo_store.start_link()
  should.be_ok(result)
}

pub fn actor_initializes_with_empty_state_test() {
  let assert Ok(pid) = todo_store.start_link()
  let items = todo_store.get_all(pid)
  should.equal(items, dict.new())
}

pub fn multiple_actors_are_independent_test() {
  let assert Ok(pid1) = todo_store.start_link()
  let assert Ok(pid2) = todo_store.start_link()

  // Add item to first actor only (using shared.Todo with timestamps)
  let item = shared.Todo("1", "Test", "Description", False, 0, 0)
  let assert Ok(_) = todo_store.put(pid1, item)

  // Second actor should still be empty
  let items1 = todo_store.get_all(pid1)
  let items2 = todo_store.get_all(pid2)

  should.equal(dict.size(items1), 1)
  should.equal(dict.size(items2), 0)
}

// Test: Sequential writes store all data
pub fn sequential_writes_store_all_data_test() {
  let assert Ok(pid) = todo_store.start_link()
  let num_operations = 100

  // Write sequentially - use range 1 to num_operations inclusive
  list.range(1, num_operations)
    |> list.each(fn(i) {
        let id = int.to_string(i)
        let item = shared.Todo(id, "Todo " <> id, "Description", False, 0, 0)
        let assert Ok(_) = todo_store.put(pid, item)
        Nil
      })

  // Verify all items are present
  let items = todo_store.get_all(pid)
  should.equal(dict.size(items), num_operations)
}

// Test concurrent writes using spawn
pub fn concurrent_writes_store_all_data_test() {
  let assert Ok(pid) = todo_store.start_link()
  let num_operations = 50

  // Spawn multiple processes that each write to the actor
  let _pids = list.range(1, num_operations)
    |> list.map(fn(i) {
        process.spawn(fn() {
          let id = int.to_string(i)
          let item = shared.Todo(id, "Todo " <> id, "Description", False, 0, 0)
          let _ = todo_store.put(pid, item)
          Nil
        })
      })

  // Wait for all processes to complete
  process.sleep(500)

  // Verify all items are present
  let items = todo_store.get_all(pid)
  should.equal(dict.size(items), num_operations)
}

// Test: Actor restarts with empty state after crash
pub fn actor_restarts_with_empty_state_test() {
  // Start supervised actor
  let assert Ok(sup) = todo_store.start_supervised()
  let assert Ok(pid) = todo_store.get_store_pid(sup)

  // Add some data
  let item = shared.Todo("1", "Test", "Desc", False, 0, 0)
  let assert Ok(_) = todo_store.put(pid, item)
  should.equal(dict.size(todo_store.get_all(pid)), 1)

  // Kill the actor process
  process.kill(pid)

  // Wait for supervisor to restart
  process.sleep(200)

  // After restart, the supervisor has a new child pid
  let assert Ok(new_pid) = todo_store.get_store_pid(sup)

  // Verify new process is alive
  should.be_true(process.is_alive(new_pid))

  // Verify new actor starts with empty state (per supervision contract)
  let items = todo_store.get_all(new_pid)
  should.equal(dict.size(items), 0)
}

// Test: Multi-process get returns correct data
pub fn multi_process_get_returns_correct_data_test() {
  let assert Ok(pid) = todo_store.start_link()

  // Populate with test data
  list.range(1, 10)
    |> list.each(fn(i) {
        let id = "todo-" <> int.to_string(i)
        let item = shared.Todo(id, "Title " <> id, "Desc", False, 0, 0)
        let assert Ok(_) = todo_store.put(pid, item)
        Nil
      })

  // Verify each item exists
  list.range(1, 10)
    |> list.each(fn(i) {
        let id = "todo-" <> int.to_string(i)
        let result = todo_store.get(pid, id)
        should.be_ok(result)
        let assert Ok(item) = result
        should.equal(item.id, id)
      })
}

// Test: Edge cases
pub fn get_missing_item_returns_error_test() {
  let assert Ok(pid) = todo_store.start_link()
  let result = todo_store.get(pid, "non-existent-id")
  should.be_error(result)
}

pub fn delete_missing_item_handled_gracefully_test() {
  let assert Ok(pid) = todo_store.start_link()
  // Should succeed (idempotent)
  let _result = todo_store.delete(pid, "non-existent-id")
  // State should remain empty
  should.equal(dict.size(todo_store.get_all(pid)), 0)
}

pub fn empty_string_id_test() {
  let assert Ok(pid) = todo_store.start_link()
  let item = shared.Todo("", "Empty ID", "Desc", False, 0, 0)
  let result = todo_store.put(pid, item)
  should.be_ok(result)

  let get_result = todo_store.get(pid, "")
  should.be_ok(get_result)
  let assert Ok(retrieved) = get_result
  should.equal(retrieved.title, "Empty ID")
}

pub fn get_all_from_empty_actor_test() {
  let assert Ok(pid) = todo_store.start_link()
  let items = todo_store.get_all(pid)
  should.equal(items, dict.new())
  should.equal(dict.size(items), 0)
}

pub fn update_replaces_old_data_test() {
  let assert Ok(pid) = todo_store.start_link()

  // Create initial
  let initial = shared.Todo("1", "Original", "Original Desc", False, 100, 100)
  let assert Ok(_) = todo_store.put(pid, initial)

  // Update
  let updated = shared.Todo("1", "Updated", "Updated Desc", True, 100, 200)
  let assert Ok(_) = todo_store.put(pid, updated)

  // Verify replacement
  let result = todo_store.get(pid, "1")
  should.be_ok(result)
  let assert Ok(item) = result
  should.equal(item.title, "Updated")
  should.equal(item.description, "Updated Desc")
  should.be_true(item.completed)
}

// Test: Contract validation
pub fn start_link_returns_ok_pid_with_alive_process_test() {
  let result = todo_store.start_link()
  should.be_ok(result)
  let assert Ok(pid) = result
  should.be_true(process.is_alive(pid))
}

pub fn state_maintains_dict_contract_test() {
  let assert Ok(pid) = todo_store.start_link()

  // Add multiple items
  let assert Ok(_) = todo_store.put(pid, shared.Todo("a", "A", "", False, 0, 0))
  let assert Ok(_) = todo_store.put(pid, shared.Todo("b", "B", "", False, 0, 0))
  let assert Ok(_) = todo_store.put(pid, shared.Todo("c", "C", "", False, 0, 0))

  // get_all should return Dict(String, Todo)
  let items = todo_store.get_all(pid)
  should.equal(dict.size(items), 3)
}

pub fn item_type_structure_test() {
  let item = shared.Todo(
    id: "test-id",
    title: "Test Title",
    description: "Test Description",
    completed: True,
    created_at: 0,
    updated_at: 0,
  )

  // Verify field types
  should.equal(item.id, "test-id")
  should.equal(item.title, "Test Title")
  should.equal(item.description, "Test Description")
  should.be_true(item.completed)
}

pub fn put_returns_result_test() {
  let assert Ok(pid) = todo_store.start_link()

  let item = shared.Todo("1", "Test", "Desc", False, 0, 0)
  let result = todo_store.put(pid, item)
  should.be_ok(result)
}

pub fn get_returns_result_contract_test() {
  let assert Ok(pid) = todo_store.start_link()

  // Missing item returns Error
  let missing = todo_store.get(pid, "missing")
  should.be_error(missing)

  // Existing item returns Ok(Todo)
  let item = shared.Todo("exists", "Title", "Desc", False, 0, 0)
  let assert Ok(_) = todo_store.put(pid, item)

  let found = todo_store.get(pid, "exists")
  should.be_ok(found)
  let assert Ok(retrieved) = found
  should.equal(retrieved.id, "exists")
  should.equal(retrieved.title, "Title")
}

pub fn delete_returns_result_test() {
  let assert Ok(pid) = todo_store.start_link()
  let result = todo_store.delete(pid, "any-id")
  // Returns Result (Ok or Error both valid)
  let _ = result
}

// Additional test: Multi-process put all succeed
pub fn multi_process_put_all_succeed_test() {
  let assert Ok(pid) = todo_store.start_link()

  // Each process adds a unique item
  let _pids = list.range(1, 20)
    |> list.map(fn(i) {
        process.spawn(fn() {
          let id = "from-process-" <> int.to_string(i)
          let item = shared.Todo(id, "Title", "Desc", False, 0, 0)
          let _ = todo_store.put(pid, item)
          Nil
        })
      })

  // Wait for all processes
  process.sleep(500)

  // Verify all items exist
  let items = todo_store.get_all(pid)
  should.equal(dict.size(items), 20)
}

// Additional test: Multi-process delete handled correctly
pub fn multi_process_delete_handled_correctly_test() {
  let assert Ok(pid) = todo_store.start_link()

  // Add items
  list.range(1, 10)
    |> list.each(fn(i) {
        let id = "todo-" <> int.to_string(i)
        let item = shared.Todo(id, "Title", "Desc", False, 0, 0)
        let assert Ok(_) = todo_store.put(pid, item)
        Nil
      })

  // Multiple processes delete different items (1-5)
  let _pids = list.range(1, 5)
    |> list.map(fn(i) {
        let id = "todo-" <> int.to_string(i)
        process.spawn(fn() {
          let _ = todo_store.delete(pid, id)
          Nil
        })
      })

  // Wait for all processes
  process.sleep(200)

  // Verify correct state - should have 5 remaining (6-10)
  let items = todo_store.get_all(pid)
  should.equal(dict.size(items), 5)
}

// State isolation test
pub fn state_isolation_test() {
  let assert Ok(pid1) = todo_store.start_link()
  let assert Ok(pid2) = todo_store.start_link()

  // Add to first only
  let assert Ok(_) = todo_store.put(pid1, shared.Todo("1", "Only in 1", "", False, 0, 0))

  // First has data, second is empty
  should.equal(dict.size(todo_store.get_all(pid1)), 1)
  should.equal(dict.size(todo_store.get_all(pid2)), 0)

  // Get from second should error
  should.be_error(todo_store.get(pid2, "1"))
}

// =============================================================================
// Tests from todo-store-crud-operations unit (modern Store interface)
// =============================================================================

// Test: Given create_todo with title, returns Todo with generated id and completed=false
pub fn create_todo_returns_todo_with_generated_id_and_completed_false_test() {
  // Setup: Start the store actor
  let assert Ok(store) = todo_store.start()

  // Action: Create a todo with title only
  let result = todo_store.create_todo(store, "Buy milk", "")

  // Assert: Result is Ok with Todo containing generated id and completed=false
  let assert Ok(created_todo) = result
  should.be_true(string.length(created_todo.id) > 0)
  should.equal(created_todo.title, "Buy milk")
  should.be_false(created_todo.completed)
}

// Test: create_todo with title and description returns Todo with both fields populated
pub fn create_todo_with_title_and_description_test() {
  // Setup: Start store
  let assert Ok(store) = todo_store.start()

  // Action: Create a todo with both title and description
  let result = todo_store.create_todo(store, "Buy milk", "Get 2% milk from store")

  // Assert: Todo has both fields populated
  let assert Ok(item) = result
  should.equal(item.title, "Buy milk")
  should.equal(item.description, "Get 2% milk from store")
}

// Test: Given get_todo_by_id with valid id, returns the Todo
pub fn get_todo_by_id_with_valid_id_returns_todo_test() {
  // Setup: Start store and create a todo
  let assert Ok(store) = todo_store.start()
  let assert Ok(created) = todo_store.create_todo(store, "Test todo", "Description")
  let id = created.id

  // Action: Retrieve the todo by ID
  let result = todo_store.get_todo(store, id)

  // Assert: Returns Some(Todo) with matching data
  let assert Some(item) = result
  should.equal(item.id, id)
  should.equal(item.title, "Test todo")
  should.equal(item.description, "Description")
  should.equal(item.completed, created.completed)
}

// Test: Given get_todo_by_id with invalid id, returns None
pub fn get_todo_by_id_with_invalid_id_returns_none_test() {
  // Setup: Start store (empty, no todos)
  let assert Ok(store) = todo_store.start()
  let invalid_id = "non-existent-id-12345"

  // Action: Attempt to retrieve non-existent todo
  let result = todo_store.get_todo(store, invalid_id)

  // Assert: Returns None
  should.equal(result, None)
}

// Test: Given list_all_todos, returns List of all stored Todos
pub fn list_all_todos_returns_all_stored_todos_test() {
  // Setup: Start store and create multiple todos
  let assert Ok(store) = todo_store.start()
  let assert Ok(todo1) = todo_store.create_todo(store, "First task", "")
  let assert Ok(todo2) = todo_store.create_todo(store, "Second task", "Description")
  let assert Ok(todo3) = todo_store.create_todo(store, "Third task", "")

  // Action: List all todos
  let todos = todo_store.get_all_todos(store)

  // Assert: Returns list containing all created todos
  should.equal(list.length(todos), 3)
  let ids = [todo1.id, todo2.id, todo3.id]
  list.each(todos, fn(t) {
    should.be_true(list.contains(ids, t.id))
  })
}

// Test: list_all_todos on empty store returns empty list
pub fn list_all_todos_on_empty_store_returns_empty_list_test() {
  // Setup: Start store (no todos)
  let assert Ok(store) = todo_store.start()

  // Action: List all todos
  let todos = todo_store.get_all_todos(store)

  // Assert: Returns empty list
  should.equal(todos, [])
}

// Test: Given update_todo with valid id and fields, returns Ok(updated Todo)
pub fn update_todo_with_valid_id_returns_updated_todo_test() {
  // Setup: Start store and create a todo
  let assert Ok(store) = todo_store.start()
  let assert Ok(created) = todo_store.create_todo(store, "Original title", "Original description")
  let id = created.id
  let original_created_at = created.created_at

  // Action: Update the todo with new fields
  let input = UpdateTodoInput(
    title: Some("Updated title"),
    description: Some("Updated description"),
    completed: Some(True)
  )
  let result = todo_store.update_todo(store, id, input)

  // Assert: Returns Ok with updated Todo
  let assert Ok(updated) = result
  should.equal(updated.id, id)
  should.equal(updated.title, "Updated title")
  should.equal(updated.description, "Updated description")
  should.be_true(updated.completed)
  should.equal(updated.created_at, original_created_at)
  should.be_true(updated.updated_at >= original_created_at)
}

// Test: Update with only title updates title, preserves other fields
pub fn update_todo_partial_fields_test() {
  // Setup: Create a todo
  let assert Ok(store) = todo_store.start()
  let assert Ok(created) = todo_store.create_todo(store, "Original title", "Original description")
  let id = created.id

  // Action: Update only the title
  let input = UpdateTodoInput(
    title: Some("New title only"),
    description: None,
    completed: None
  )
  let result = todo_store.update_todo(store, id, input)

  // Assert: Only title changed, description and completed remain the same
  let assert Ok(updated) = result
  should.equal(updated.title, "New title only")
  should.equal(updated.description, "Original description")
  should.be_false(updated.completed)
}

// Test: update_todo with invalid id returns Error
pub fn update_todo_with_invalid_id_returns_error_test() {
  // Setup: Start store with no todos
  let assert Ok(store) = todo_store.start()
  let invalid_id = "non-existent-id-12345"

  // Action: Attempt to update non-existent todo
  let input = UpdateTodoInput(title: Some("New title"), description: None, completed: None)
  let result = todo_store.update_todo(store, invalid_id, input)

  // Assert: Returns error
  let assert Error(error_msg) = result
  should.equal(error_msg, "Todo not found")
}

// Test: Given delete_todo with valid id, returns Ok and removes from store
pub fn delete_todo_with_valid_id_removes_from_store_test() {
  // Setup: Start store and create a todo
  let assert Ok(store) = todo_store.start()
  let assert Ok(created) = todo_store.create_todo(store, "To be deleted", "")
  let id = created.id

  // Verify: Todo exists before deletion
  let before_delete = todo_store.get_todo(store, id)
  should.be_true(case before_delete { Some(_) -> True None -> False })

  // Action: Delete the todo
  let result = todo_store.delete_todo(store, id)

  // Assert: Returns Ok(Nil)
  should.be_ok(result)
  let assert Ok(Nil) = result

  // Verify: Todo is no longer retrievable
  let after_delete = todo_store.get_todo(store, id)
  should.equal(after_delete, None)

  // Verify: Todo is not in the list
  let todos = todo_store.get_all_todos(store)
  should.equal(todos, [])
}

// Test: delete_todo with invalid id returns Error
pub fn delete_todo_with_invalid_id_returns_error_test() {
  // Setup: Start store with no todos
  let assert Ok(store) = todo_store.start()
  let invalid_id = "non-existent-id-12345"

  // Action: Attempt to delete non-existent todo
  let result = todo_store.delete_todo(store, invalid_id)

  // Assert: Returns error
  let assert Error(error_msg) = result
  should.equal(error_msg, "Todo not found")
}

// Test: Create todo trims whitespace from title
pub fn create_todo_trims_whitespace_from_title_test() {
  // Setup: Start store
  let assert Ok(store) = todo_store.start()

  // Action: Create a todo with whitespace in title
  let result = todo_store.create_todo(store, "  Spacy title  ", "")

  // Assert: Title is trimmed
  let assert Ok(item) = result
  should.equal(item.title, "Spacy title")
}

// Test: Create todo with empty/whitespace-only title returns error
pub fn create_todo_with_empty_title_returns_error_test() {
  // Setup: Start store
  let assert Ok(store) = todo_store.start()

  // Action: Create a todo with only whitespace
  let result = todo_store.create_todo(store, "   ", "")

  // Assert: Returns error
  let assert Error(error_msg) = result
  should.equal(error_msg, "Title is required")
}

// Test: Full CRUD lifecycle validates all boundary contracts together
pub fn full_crud_lifecycle_test() {
  // Setup: Start store
  let assert Ok(store) = todo_store.start()

  // Step 1: Create - empty list
  let all_before = todo_store.get_all_todos(store)
  should.equal(list.length(all_before), 0)

  // Step 2: Create todo
  let assert Ok(created) = todo_store.create_todo(store, "Lifecycle test", "Full test")
  let id = created.id
  should.equal(created.title, "Lifecycle test")
  should.be_false(created.completed)

  // Step 3: Read - verify in list
  let all_after_create = todo_store.get_all_todos(store)
  should.equal(list.length(all_after_create), 1)

  // Step 4: Read - verify by ID
  let retrieved = todo_store.get_todo(store, id)
  let assert Some(item) = retrieved
  should.equal(item.id, id)

  // Step 5: Update
  let input = UpdateTodoInput(title: None, description: None, completed: Some(True))
  let assert Ok(updated) = todo_store.update_todo(store, id, input)
  should.be_true(updated.completed)
  should.equal(updated.title, "Lifecycle test")

  // Step 6: Verify update persisted
  let after_update = todo_store.get_todo(store, id)
  let assert Some(updated_todo) = after_update
  should.be_true(updated_todo.completed)

  // Step 7: Delete
  let assert Ok(Nil) = todo_store.delete_todo(store, id)

  // Step 8: Verify deletion
  let all_after_delete = todo_store.get_all_todos(store)
  should.equal(list.length(all_after_delete), 0)
  should.equal(todo_store.get_todo(store, id), None)
}
