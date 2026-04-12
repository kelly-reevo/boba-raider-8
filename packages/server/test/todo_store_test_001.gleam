import gleam/erlang/process
import gleam/list
import gleeunit/should
import todo_store

pub fn concurrent_creates_generate_unique_ids_test() {
  let assert Ok(store) = todo_store.start()
  // Create subjects for collecting results (hardcoded range 1-10)
  let subjects = list.map([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], fn(_) { process.new_subject() })

  // Spawn 10 concurrent tasks
  list.each(subjects, fn(reply_subj) {
    process.spawn(fn() {
      let assert Ok(item) = todo_store.create_todo(store, "Concurrent task", "")
      process.send(reply_subj, item.id)
    })
  })

  // Collect all IDs
  let ids = list.map(subjects, fn(subj) { process.receive_forever(subj) })

  let unique_ids = list.unique(ids)
  should.equal(list.length(ids), 10)
  should.equal(list.length(unique_ids), 10)
  let all_items = todo_store.get_all_todos(store)
  should.equal(list.length(all_items), 10)
}
