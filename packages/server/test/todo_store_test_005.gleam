import gleam/erlang/process
import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/string
import gleeunit/should
import shared.{None as SharedNone, Some as SharedSome, Todo, UpdateTodoInput}
import todo_store

pub fn update_only_modifies_provided_fields_test() {
  let assert Ok(store) = todo_store.start()
  let assert Ok(created_item) = todo_store.create_todo(store, "Original title", "Original description")
  let id = created_item.id
  let original_created_at = created_item.created_at
  let original_updated_at = created_item.updated_at
  process.sleep(10)
  let input = UpdateTodoInput(
    title: SharedSome("Updated title"),
    description: SharedNone,
    completed: SharedNone,
  )
  let result = todo_store.update_todo(store, id, input)
  let assert Ok(updated) = result
  should.equal(updated.id, id)
  should.equal(updated.title, "Updated title")
  should.equal(updated.description, "Original description")
  should.be_false(updated.completed)
  should.equal(updated.created_at, original_created_at)
  should.be_true(updated.updated_at > original_updated_at)
}

pub fn update_description_only_test() {
  let assert Ok(store) = todo_store.start()
  let assert Ok(created_item) = todo_store.create_todo(store, "Title", "Original desc")
  let id = created_item.id
  let input = UpdateTodoInput(
    title: SharedNone,
    description: SharedSome("Updated description"),
    completed: SharedNone,
  )
  let result = todo_store.update_todo(store, id, input)
  let assert Ok(updated) = result
  should.equal(updated.title, "Title")
  should.equal(updated.description, "Updated description")
  should.be_false(updated.completed)
}

pub fn update_completed_only_test() {
  let assert Ok(store) = todo_store.start()
  let assert Ok(created_item) = todo_store.create_todo(store, "Title", "Desc")
  let id = created_item.id
  let input = UpdateTodoInput(
    title: SharedNone,
    description: SharedNone,
    completed: SharedSome(True),
  )
  let result = todo_store.update_todo(store, id, input)
  let assert Ok(updated) = result
  should.equal(updated.title, "Title")
  should.equal(updated.description, "Desc")
  should.be_true(updated.completed)
}

pub fn update_nonexistent_returns_error_test() {
  let assert Ok(store) = todo_store.start()
  let input = UpdateTodoInput(
    title: SharedSome("New title"),
    description: SharedNone,
    completed: SharedNone,
  )
  let result = todo_store.update_todo(store, "non-existent-id", input)
  let assert Error(msg) = result
  should.equal(msg, "Todo not found")
}