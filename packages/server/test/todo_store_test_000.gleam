import gleam/erlang/process
import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/string
import gleeunit/should
import shared.{None as SharedNone, Some as SharedSome, Todo, UpdateTodoInput}
import todo_store

pub fn create_returns_todo_with_generated_id_test() {
  let assert Ok(store) = todo_store.start()
  let result = todo_store.create_todo(store, "Buy groceries", "Milk and eggs")
  let assert Ok(item) = result
  should.be_true(string.length(item.id) > 0)
  should.equal(item.title, "Buy groceries")
  should.equal(item.description, "Milk and eggs")
  should.be_false(item.completed)
}

pub fn created_item_is_retrievable_by_id_test() {
  let assert Ok(store) = todo_store.start()
  let assert Ok(created_item) = todo_store.create_todo(store, "Test todo", "Description")
  let id = created_item.id
  let retrieved = todo_store.get_todo(store, id)
  let assert Some(found_item) = retrieved
  should.equal(found_item.id, id)
  should.equal(found_item.title, "Test todo")
  should.equal(found_item.description, "Description")
}