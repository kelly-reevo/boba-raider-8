import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit/should
import shared.{UpdateTodoInput}
import todo_store

pub fn full_crud_lifecycle_test() {
  let assert Ok(store) = todo_store.start()
  let assert Ok(created_item) = todo_store.create_todo(store, "Lifecycle test", Some("Original"), shared.Medium, False)
  let id = created_item.id
  should.be_true(string.length(id) > 0)
  let assert Some(found) = todo_store.get_todo(store, id)
  should.equal(found.title, "Lifecycle test")
  let all_before = todo_store.get_all_todos(store)
  should.equal(list.length(all_before), 1)
  let input = UpdateTodoInput(
    title: Some("Updated title"),
    description: Some("Updated description"),
    completed: Some(True),
  )
  let assert Ok(updated) = todo_store.update_todo(store, id, input)
  should.equal(updated.title, "Updated title")
  should.equal(updated.description, Some("Updated description"))
  should.be_true(updated.completed)
  let assert Some(after_update) = todo_store.get_todo(store, id)
  should.equal(after_update.title, "Updated title")
  let assert Ok(_) = todo_store.delete_todo(store, id)
  should.equal(todo_store.get_todo(store, id), None)
  let all_after = todo_store.get_all_todos(store)
  should.equal(list.length(all_after), 0)
}
