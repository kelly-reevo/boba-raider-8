import gleam/erlang/process
import gleam/list
import gleam/option.{None}
import gleam/string
import gleeunit/should
import shared
import todo_store

pub fn list_all_returns_all_stored_items_test() {
  let assert Ok(store) = todo_store.start()
  let assert Ok(item1) = todo_store.create_todo(store, "First task", None, shared.Medium, False)
  let assert Ok(item2) = todo_store.create_todo(store, "Second task", None, shared.Medium, False)
  let assert Ok(item3) = todo_store.create_todo(store, "Third task", None, shared.Medium, False)
  let all = todo_store.get_all_todos(store)
  should.equal(list.length(all), 3)
  let ids = list.map(all, fn(t) { t.id })
  should.be_true(list.contains(ids, item1.id))
  should.be_true(list.contains(ids, item2.id))
  should.be_true(list.contains(ids, item3.id))
}

pub fn list_all_returns_items_in_creation_order_test() {
  let assert Ok(store) = todo_store.start()
  let assert Ok(_item1) = todo_store.create_todo(store, "First", None, shared.Medium, False)
  process.sleep(10)
  let assert Ok(_item2) = todo_store.create_todo(store, "Second", None, shared.Medium, False)
  process.sleep(10)
  let assert Ok(_item3) = todo_store.create_todo(store, "Third", None, shared.Medium, False)
  let all = todo_store.get_all_todos(store)
  should.equal(list.length(all), 3)
  let timestamps = list.map(all, fn(t) { t.created_at })
  let sorted_timestamps = list.sort(timestamps, string.compare)
  should.equal(timestamps, sorted_timestamps)
}