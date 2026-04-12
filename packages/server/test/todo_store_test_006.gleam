import gleam/list
import gleam/option.{None}
import gleeunit/should
import shared
import todo_store

pub fn delete_removes_existing_item_test() {
  let assert Ok(store) = todo_store.start()
  let assert Ok(created_item) = todo_store.create_todo(store, "To delete", None, shared.Medium, False)
  let id = created_item.id
  let result = todo_store.delete_todo(store, id)
  should.be_ok(result)
}

pub fn delete_makes_item_unretrievable_test() {
  let assert Ok(store) = todo_store.start()
  let assert Ok(created_item) = todo_store.create_todo(store, "To delete", None, shared.Medium, False)
  let id = created_item.id
  let assert Ok(_) = todo_store.delete_todo(store, id)
  let retrieved = todo_store.get_todo(store, id)
  should.equal(retrieved, None)
  let all = todo_store.get_all_todos(store)
  let ids = list.map(all, fn(t) { t.id })
  should.be_false(list.contains(ids, id))
}

pub fn delete_nonexistent_returns_error_test() {
  let assert Ok(store) = todo_store.start()
  let result = todo_store.delete_todo(store, "non-existent-id")
  let assert Error(msg) = result
  should.equal(msg, "Todo not found")
}
