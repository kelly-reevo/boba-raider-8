import gleam/erlang/process
import gleam/option.{None, Some}
import gleam/string
import gleeunit/should
import shared.{UpdateTodoInput}
import todo_store

pub fn update_only_modifies_provided_fields_test() {
  let assert Ok(store) = todo_store.start()
  let assert Ok(created_item) = todo_store.create_todo(store, "Original title", Some("Original description"))
  let id = created_item.id
  let original_created_at = created_item.created_at
  let original_updated_at = created_item.updated_at
  process.sleep(1000)
  let input = UpdateTodoInput(
    title: Some("Updated title"),
    description: None,
    completed: None,
  )
  let result = todo_store.update_todo(store, id, input)
  let assert Ok(updated) = result
  should.equal(updated.id, id)
  should.equal(updated.title, "Updated title")
  should.equal(updated.description, Some("Original description"))
  should.be_false(updated.completed)
  should.equal(updated.created_at, original_created_at)
  should.be_true(updated.updated_at != original_updated_at)
}

pub fn update_description_only_test() {
  let assert Ok(store) = todo_store.start()
  let assert Ok(created_item) = todo_store.create_todo(store, "Title", Some("Original desc"))
  let id = created_item.id
  let input = UpdateTodoInput(
    title: None,
    description: Some("Updated description"),
    completed: None,
  )
  let result = todo_store.update_todo(store, id, input)
  let assert Ok(updated) = result
  should.equal(updated.title, "Title")
  should.equal(updated.description, Some("Updated description"))
  should.be_false(updated.completed)
}

pub fn update_completed_only_test() {
  let assert Ok(store) = todo_store.start()
  let assert Ok(created_item) = todo_store.create_todo(store, "Title", Some("Desc"))
  let id = created_item.id
  let input = UpdateTodoInput(
    title: None,
    description: None,
    completed: Some(True),
  )
  let result = todo_store.update_todo(store, id, input)
  let assert Ok(updated) = result
  should.equal(updated.title, "Title")
  should.equal(updated.description, Some("Desc"))
  should.be_true(updated.completed)
}

pub fn update_nonexistent_returns_error_test() {
  let assert Ok(store) = todo_store.start()
  let input = UpdateTodoInput(
    title: Some("New title"),
    description: None,
    completed: None,
  )
  let result = todo_store.update_todo(store, "non-existent-id", input)
  let assert Error(msg) = result
  should.equal(msg, "Todo not found")
}
