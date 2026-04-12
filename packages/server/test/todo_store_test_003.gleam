import gleam/erlang/process
import gleam/option.{None}
import gleeunit/should
import todo_store

pub fn get_by_id_returns_none_for_nonexistent_item_test() {
  let assert Ok(store) = todo_store.start()
  let result = todo_store.get_todo(store, "non-existent-id-12345")
  should.equal(result, None)
}