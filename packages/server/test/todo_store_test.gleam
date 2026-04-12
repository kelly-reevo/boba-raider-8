import gleeunit/should
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import shared.{UpdateTodoInput}
import todo_store

// Test: Given create_todo with title, returns Todo with generated id and completed=false
// Boundary: create_todo(title: String, description: String) -> Result(Todo, String)
pub fn create_todo_returns_todo_with_generated_id_and_completed_false_test() {
  // Setup: Start the store actor
  let assert Ok(store) = todo_store.start()

  // Action: Create a todo with title only (empty description)
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
// Boundary: get_todo(store, id: String) -> Option(Todo)
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

// Test: Given get_todo_by_id with invalid id, returns None (represents NotFound)
// Boundary: get_todo(store, id: String) -> Option(Todo) returns None for invalid ID
pub fn get_todo_by_id_with_invalid_id_returns_none_test() {
  // Setup: Start store (empty, no todos)
  let assert Ok(store) = todo_store.start()
  let invalid_id = "non-existent-id-12345"

  // Action: Attempt to retrieve non-existent todo
  let result = todo_store.get_todo(store, invalid_id)

  // Assert: Returns None (equivalent to NotFound in the boundary contract)
  should.equal(result, None)
}

// Test: Given list_all_todos, returns List of all stored Todos
// Boundary: get_all_todos(store) -> List(Todo)
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
// Boundary: update_todo(store, id: String, UpdateTodoInput) -> Result(Todo, String)
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
// Boundary: update_todo with partial UpdateTodoInput preserves unspecified fields
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
// Boundary: delete_todo(store, id: String) -> Result(Nil, String)
pub fn delete_todo_with_valid_id_removes_from_store_test() {
  // Setup: Start store and create a todo
  let assert Ok(store) = todo_store.start()
  let assert Ok(created) = todo_store.create_todo(store, "To be deleted", "")
  let id = created.id

  // Verify: Todo exists before deletion
  let before_delete = todo_store.get_todo(store, id)
  should.be_true(case before_delete { option.Some(_) -> True option.None -> False })

  // Action: Delete the todo
  let result = todo_store.delete_todo(store, id)

  // Assert: Returns Ok(Nil) (representing Ok(Deleted))
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
// Boundary: create_todo validates and cleans input before storage
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
// Boundary: create_todo validates title and returns Error for invalid input
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
// Boundaries tested: create_todo, get_all_todos, get_todo, update_todo, delete_todo
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
