import gleeunit
import gleeunit/should
import todo_store
import gleam/option.{Some, None}
import gleam/list

pub fn main() {
  gleeunit.main()
}

// List returns all stored todos
pub fn list_returns_all_todos_test() {
  let assert Ok(actor) = todo_store.start()
  
  // Insert multiple todos
  let todo1 = todo_store.TodoData(
    title: "First todo",
    description: None,
    priority: todo_store.Low,
    completed: False
  )
  let todo2 = todo_store.TodoData(
    title: "Second todo",
    description: Some("With description"),
    priority: todo_store.High,
    completed: True
  )
  let id1 = todo_store.insert(actor, todo1)
  let id2 = todo_store.insert(actor, todo2)
  
  // List should return both
  let todos = todo_store.list(actor)
  
  should.equal(list.length(todos), 2)
  
  // Verify both IDs are in the list
  let ids = list.map(todos, fn(t) { t.id })
  should.be_true(list.contains(ids, id1))
  should.be_true(list.contains(ids, id2))
}
