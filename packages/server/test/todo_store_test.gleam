// Test file for todo_store module
// Verifies all behaviors from cyclone test specifications

import gleeunit
import gleeunit/should
import gleam/dict
import gleam/erlang/process
import gleam/int
import gleam/list
import todo_store

pub fn main() {
  gleeunit.main()
}

// Test 000: Actor initializes with empty state when started
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

  // Add item to first actor only
  let item = todo_store.Todo("1", "Test", "Description", False)
  let assert Ok(_) = todo_store.put(pid1, item)

  // Second actor should still be empty
  let items1 = todo_store.get_all(pid1)
  let items2 = todo_store.get_all(pid2)

  should.equal(dict.size(items1), 1)
  should.equal(dict.size(items2), 0)
}

// Test 001: Sequential writes store all data
pub fn sequential_writes_store_all_data_test() {
  let assert Ok(pid) = todo_store.start_link()
  let num_operations = 100

  // Write sequentially - use range 1 to num_operations inclusive
  list.range(1, num_operations)
    |> list.each(fn(i) {
        let id = int.to_string(i)
        let item = todo_store.Todo(id, "Todo " <> id, "Description", False)
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
          let item = todo_store.Todo(id, "Todo " <> id, "Description", False)
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

// Test 002: Actor restarts with empty state after crash
// Note: After restart, the supervisor creates a new actor process
// The old registry entry won't work, but the new actor starts fresh
pub fn actor_restarts_with_empty_state_test() {
  // Start supervised actor
  let assert Ok(sup) = todo_store.start_supervised()
  let assert Ok(pid) = todo_store.get_store_pid(sup)

  // Add some data
  let item = todo_store.Todo("1", "Test", "Desc", False)
  let assert Ok(_) = todo_store.put(pid, item)
  should.equal(dict.size(todo_store.get_all(pid)), 1)

  // Kill the actor process
  process.kill(pid)

  // Wait for supervisor to restart
  process.sleep(200)

  // After restart, the supervisor has a new child pid
  // The registry should have the new mapping
  let assert Ok(new_pid) = todo_store.get_store_pid(sup)

  // Verify new process is alive
  should.be_true(process.is_alive(new_pid))

  // Verify new actor starts with empty state (per supervision contract)
  let items = todo_store.get_all(new_pid)
  should.equal(dict.size(items), 0)
}

// Test 003: Multi-process get returns correct data
pub fn multi_process_get_returns_correct_data_test() {
  let assert Ok(pid) = todo_store.start_link()

  // Populate with test data
  list.range(1, 10)
    |> list.each(fn(i) {
        let id = "todo-" <> int.to_string(i)
        let item = todo_store.Todo(id, "Title " <> id, "Desc", False)
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

// Test 004: Edge cases
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
  let item = todo_store.Todo("", "Empty ID", "Desc", False)
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
  let initial = todo_store.Todo("1", "Original", "Original Desc", False)
  let assert Ok(_) = todo_store.put(pid, initial)

  // Update
  let updated = todo_store.Todo("1", "Updated", "Updated Desc", True)
  let assert Ok(_) = todo_store.put(pid, updated)

  // Verify replacement
  let result = todo_store.get(pid, "1")
  should.be_ok(result)
  let assert Ok(item) = result
  should.equal(item.title, "Updated")
  should.equal(item.description, "Updated Desc")
  should.be_true(item.completed)
}

// Test 005: Contract validation
pub fn start_link_returns_ok_pid_with_alive_process_test() {
  let result = todo_store.start_link()
  should.be_ok(result)
  let assert Ok(pid) = result
  should.be_true(process.is_alive(pid))
}

pub fn state_maintains_dict_contract_test() {
  let assert Ok(pid) = todo_store.start_link()

  // Add multiple items
  let assert Ok(_) = todo_store.put(pid, todo_store.Todo("a", "A", "", False))
  let assert Ok(_) = todo_store.put(pid, todo_store.Todo("b", "B", "", False))
  let assert Ok(_) = todo_store.put(pid, todo_store.Todo("c", "C", "", False))

  // get_all should return Dict(String, Todo)
  let items = todo_store.get_all(pid)
  should.equal(dict.size(items), 3)
}

pub fn item_type_structure_test() {
  let item = todo_store.Todo(
    id: "test-id",
    title: "Test Title",
    description: "Test Description",
    completed: True
  )

  // Verify field types
  should.equal(item.id, "test-id")
  should.equal(item.title, "Test Title")
  should.equal(item.description, "Test Description")
  should.be_true(item.completed)
}

pub fn put_returns_result_test() {
  let assert Ok(pid) = todo_store.start_link()

  let item = todo_store.Todo("1", "Test", "Desc", False)
  let result = todo_store.put(pid, item)
  should.be_ok(result)
}

pub fn get_returns_result_contract_test() {
  let assert Ok(pid) = todo_store.start_link()

  // Missing item returns Error
  let missing = todo_store.get(pid, "missing")
  should.be_error(missing)

  // Existing item returns Ok(Todo)
  let item = todo_store.Todo("exists", "Title", "Desc", False)
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
          let item = todo_store.Todo(id, "Title", "Desc", False)
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
        let item = todo_store.Todo(id, "Title", "Desc", False)
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
  let assert Ok(_) = todo_store.put(pid1, todo_store.Todo("1", "Only in 1", "", False))

  // First has data, second is empty
  should.equal(dict.size(todo_store.get_all(pid1)), 1)
  should.equal(dict.size(todo_store.get_all(pid2)), 0)

  // Get from second should error
  should.be_error(todo_store.get(pid2, "1"))
}
