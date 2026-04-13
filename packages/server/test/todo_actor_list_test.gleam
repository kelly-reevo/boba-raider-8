import gleeunit
import gleeunit/should
import gleam/erlang/process
import gleam/list
import gleam/otp/actor
import todo_actor.{All, Completed}

pub fn main() {
  gleeunit.main()
}

pub fn list_without_filter_returns_all_todos_test() {
  // Given: todos exist in state with varying properties
  let todo1 = todo_actor.Todo(
    id: "todo-001",
    title: "First Todo",
    description: "Description 1",
    priority: "high",
    completed: True,
    created_at: 1000
  )
  let todo2 = todo_actor.Todo(
    id: "todo-002",
    title: "Second Todo",
    description: "Description 2",
    priority: "medium",
    completed: False,
    created_at: 2000
  )
  let todo3 = todo_actor.Todo(
    id: "todo-003",
    title: "Third Todo",
    description: "Description 3",
    priority: "low",
    completed: True,
    created_at: 3000
  )
  let initial_state = [todo1, todo2, todo3]

  // Start actor with initial state
  let assert Ok(actor_pid) = todo_actor.start(initial_state)

  // When: list message is sent without filter (All)
  let reply_subject = process.new_subject()
  actor.send(actor_pid, todo_actor.List(All, reply_subject))

  // Then: actor returns array of all todos ordered by created_at descending
  let result = process.receive(reply_subject, 1000)
  should.be_ok(result)

  let todos = result |> should.be_ok
  should.equal(list.length(todos), 3)
  // Verify descending order: newest first (3000, 2000, 1000)
  let assert [first, second, third] = todos
  should.equal(first.id, "todo-003")
  should.equal(second.id, "todo-002")
  should.equal(third.id, "todo-001")
}

pub fn list_with_completed_true_filter_returns_only_completed_todos_test() {
  // Given: todos with mixed completion status
  let completed_todo1 = todo_actor.Todo(
    id: "todo-001",
    title: "Completed Todo 1",
    description: "Done",
    priority: "high",
    completed: True,
    created_at: 1000
  )
  let active_todo = todo_actor.Todo(
    id: "todo-002",
    title: "Active Todo",
    description: "Not done",
    priority: "medium",
    completed: False,
    created_at: 2000
  )
  let completed_todo2 = todo_actor.Todo(
    id: "todo-003",
    title: "Completed Todo 2",
    description: "Also done",
    priority: "low",
    completed: True,
    created_at: 3000
  )
  let initial_state = [completed_todo1, active_todo, completed_todo2]

  // Start actor with initial state
  let assert Ok(actor_pid) = todo_actor.start(initial_state)

  // When: list message includes completed=true filter
  let reply_subject = process.new_subject()
  actor.send(actor_pid, todo_actor.List(Completed(True), reply_subject))

  // Then: only completed todos returned, ordered by created_at descending
  let result = process.receive(reply_subject, 1000)
  should.be_ok(result)

  let todos = result |> should.be_ok
  should.equal(list.length(todos), 2)

  // Verify all returned todos are completed
  let all_completed = todos |> list.all(fn(t) { t.completed })
  should.be_true(all_completed)

  // Verify descending order: todo-003 (3000) before todo-001 (1000)
  let assert [first, second] = todos
  should.equal(first.id, "todo-003")
  should.equal(second.id, "todo-001")
}

pub fn list_with_completed_false_filter_returns_only_active_todos_test() {
  // Given: todos with mixed completion status
  let completed_todo = todo_actor.Todo(
    id: "todo-001",
    title: "Completed Todo",
    description: "Done",
    priority: "high",
    completed: True,
    created_at: 1000
  )
  let active_todo1 = todo_actor.Todo(
    id: "todo-002",
    title: "Active Todo 1",
    description: "Not done",
    priority: "medium",
    completed: False,
    created_at: 2000
  )
  let active_todo2 = todo_actor.Todo(
    id: "todo-003",
    title: "Active Todo 2",
    description: "Also not done",
    priority: "low",
    completed: False,
    created_at: 3000
  )
  let initial_state = [completed_todo, active_todo1, active_todo2]

  // Start actor with initial state
  let assert Ok(actor_pid) = todo_actor.start(initial_state)

  // When: list message includes completed=false filter
  let reply_subject = process.new_subject()
  actor.send(actor_pid, todo_actor.List(Completed(False), reply_subject))

  // Then: only active (incomplete) todos returned, ordered by created_at descending
  let result = process.receive(reply_subject, 1000)
  should.be_ok(result)

  let todos = result |> should.be_ok
  should.equal(list.length(todos), 2)

  // Verify all returned todos are NOT completed (active)
  let all_active = todos |> list.all(fn(t) { !t.completed })
  should.be_true(all_active)

  // Verify descending order: todo-003 (3000) before todo-002 (2000)
  let assert [first, second] = todos
  should.equal(first.id, "todo-003")
  should.equal(second.id, "todo-002")
}

pub fn list_with_empty_state_returns_empty_array_test() {
  // Given: empty todo state
  let initial_state = []

  // Start actor with empty state
  let assert Ok(actor_pid) = todo_actor.start(initial_state)

  // When: list message is sent without filter
  let reply_subject = process.new_subject()
  actor.send(actor_pid, todo_actor.List(All, reply_subject))

  // Then: actor returns empty array
  let result = process.receive(reply_subject, 1000)
  should.be_ok(result)

  let todos = result |> should.be_ok
  should.equal(todos, [])
  should.equal(list.length(todos), 0)
}

pub fn list_completed_true_with_empty_state_returns_empty_array_test() {
  // Given: empty todo state
  let initial_state = []

  // Start actor with empty state
  let assert Ok(actor_pid) = todo_actor.start(initial_state)

  // When: list message with completed=true filter is sent
  let reply_subject = process.new_subject()
  actor.send(actor_pid, todo_actor.List(Completed(True), reply_subject))

  // Then: actor returns empty array
  let result = process.receive(reply_subject, 1000)
  should.be_ok(result)

  let todos = result |> should.be_ok
  should.equal(todos, [])
}

pub fn list_completed_false_with_empty_state_returns_empty_array_test() {
  // Given: empty todo state
  let initial_state = []

  // Start actor with empty state
  let assert Ok(actor_pid) = todo_actor.start(initial_state)

  // When: list message with completed=false filter is sent
  let reply_subject = process.new_subject()
  actor.send(actor_pid, todo_actor.List(Completed(False), reply_subject))

  // Then: actor returns empty array
  let result = process.receive(reply_subject, 1000)
  should.be_ok(result)

  let todos = result |> should.be_ok
  should.equal(todos, [])
}
