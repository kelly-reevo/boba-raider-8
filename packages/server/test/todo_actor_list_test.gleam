import gleeunit
import gleeunit/should
import gleam/dict
import gleam/erlang/process
import gleam/list
import gleam/option.{None, Some}
import gleam/otp/actor
import todo_actor.{All, Completed}
import models/todo_item.{Todo}

pub fn main() {
  gleeunit.main()
}

pub fn list_without_filter_returns_all_todos_test() {
  // Given: start actor and create todos
  let assert Ok(actor_pid) = todo_actor.start()

  // Create todos
  let _ = todo_actor.create(actor_pid, "First Todo", "Description 1", "high")
  let _ = todo_actor.create(actor_pid, "Second Todo", "Description 2", "medium")
  let _ = todo_actor.create(actor_pid, "Third Todo", "Description 3", "low")

  // Get all todos via list API
  let todos = todo_actor.list(actor_pid, All)

  // Then: actor returns all todos
  should.equal(list.length(todos), 3)
}

pub fn list_with_completed_true_filter_returns_only_completed_todos_test() {
  // Given: start actor and create todos with mixed completion
  let assert Ok(actor_pid) = todo_actor.start()

  // Create todos
  let assert Ok(todo1) = todo_actor.create(actor_pid, "Completed Todo 1", "Done", "high")
  let assert Ok(todo2) = todo_actor.create(actor_pid, "Active Todo", "Not done", "medium")
  let assert Ok(todo3) = todo_actor.create(actor_pid, "Completed Todo 2", "Also done", "low")

  // Mark some as completed
  let _ = todo_actor.update(actor_pid, todo1.id, None, None, None, Some(True))
  let _ = todo_actor.update(actor_pid, todo3.id, None, None, None, Some(True))

  // When: list with completed=true filter
  let todos = todo_actor.list(actor_pid, Completed(True))

  // Then: only completed todos returned
  should.equal(list.length(todos), 2)

  // Verify all returned todos are completed
  let all_completed = todos |> list.all(fn(t) { t.completed })
  should.be_true(all_completed)
}

pub fn list_with_completed_false_filter_returns_only_active_todos_test() {
  // Given: start actor and create todos
  let assert Ok(actor_pid) = todo_actor.start()

  // Create todos
  let assert Ok(todo1) = todo_actor.create(actor_pid, "Completed Todo", "Done", "high")
  let assert Ok(todo2) = todo_actor.create(actor_pid, "Active Todo 1", "Not done", "medium")
  let assert Ok(todo3) = todo_actor.create(actor_pid, "Active Todo 2", "Also not done", "low")

  // Mark first as completed
  let _ = todo_actor.update(actor_pid, todo1.id, None, None, None, Some(True))

  // When: list with completed=false filter
  let todos = todo_actor.list(actor_pid, Completed(False))

  // Then: only active (incomplete) todos returned
  should.equal(list.length(todos), 2)

  // Verify all returned todos are NOT completed (active)
  let all_active = todos |> list.all(fn(t) { !t.completed })
  should.be_true(all_active)
}

pub fn list_with_empty_state_returns_empty_array_test() {
  // Given: start actor with empty state
  let assert Ok(actor_pid) = todo_actor.start()

  // When: list all todos
  let todos = todo_actor.list(actor_pid, All)

  // Then: actor returns empty list
  should.equal(todos, [])
  should.equal(list.length(todos), 0)
}

pub fn list_completed_true_with_empty_state_returns_empty_array_test() {
  // Given: start actor with empty state
  let assert Ok(actor_pid) = todo_actor.start()

  // When: list with completed=true filter
  let todos = todo_actor.list(actor_pid, Completed(True))

  // Then: actor returns empty list
  should.equal(todos, [])
}

pub fn list_completed_false_with_empty_state_returns_empty_array_test() {
  // Given: start actor with empty state
  let assert Ok(actor_pid) = todo_actor.start()

  // When: list with completed=false filter
  let todos = todo_actor.list(actor_pid, Completed(False))

  // Then: actor returns empty list
  should.equal(todos, [])
}
