import gleam/erlang/process
import gleam/option.{Some}
import gleeunit/should
import todo_store

pub fn get_by_id_returns_existing_item_test() {
  let assert Ok(store) = todo_store.start()
  let assert Ok(created_item) = todo_store.create_todo(store, "Existing item", Some("Details"))
  let id = created_item.id
  let result = todo_store.get_todo(store, id)
  let assert Some(found_item) = result
  should.equal(found_item.id, id)
  should.equal(found_item.title, "Existing item")
  should.equal(found_item.description, Some("Details"))
}