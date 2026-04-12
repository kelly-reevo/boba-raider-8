import gleeunit
import gleeunit/should
import todo_store
import gleam/option.{Some, None}
import gleam/list
import gleam/int
import gleam/string

pub fn main() {
  gleeunit.main()
}

// Given multiple sequential requests, when reading/writing, then all operations complete without data corruption
pub fn rapid_operations_no_data_corruption_test() {
  let assert Ok(actor) = todo_store.start()

  // Insert multiple todos rapidly
  let ids = list.range(0, 9)
    |> list.map(fn(i) {
      let todo_data = todo_store.TodoData(
        title: "Todo " <> int.to_string(i),
        description: None,
        priority: todo_store.Medium,
        completed: False
      )
      todo_store.insert(actor, todo_data)
    })

  // All inserts should succeed with unique IDs
  should.equal(list.length(ids), 10)

  // Verify all unique IDs
  let unique_ids = list.unique(ids)
  should.equal(list.length(unique_ids), 10)

  // Rapid reads and updates
  let update_results = ids
    |> list.map(fn(id) {
      // Read
      let assert Some(item) = todo_store.get(actor, id)
      // Update
      let changes = todo_store.TodoData(
        title: item.title <> " - updated",
        description: item.description,
        priority: item.priority,
        completed: True
      )
      todo_store.update(actor, id, changes)
    })

  // All updates should succeed
  let ok_count = update_results
    |> list.filter(fn(r) { r == todo_store.Ok })
    |> list.length
  should.equal(ok_count, 10)

  // Verify final state - all marked as completed
  let todos = todo_store.list(actor)
  let completed_count = todos
    |> list.filter(fn(t) { t.completed })
    |> list.length
  should.equal(completed_count, 10)

  // Rapid deletes
  let delete_results = ids
    |> list.map(fn(id) {
      todo_store.delete(actor, id)
    })

  // All deletes should succeed
  let delete_ok_count = delete_results
    |> list.filter(fn(r) { r == todo_store.Ok })
    |> list.length
  should.equal(delete_ok_count, 10)

  // Verify all deleted
  let remaining = todo_store.list(actor)
  should.equal(remaining, [])
}
