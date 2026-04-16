import gleeunit/should
import gleam/bool
import gleam/list
import gleam/option
import frontend/filter
import shared

// Acceptance: Given filter=All, return all todos regardless of completion status
pub fn filter_all_returns_all_todos_test() {
  let todos = [
    shared.Todo(
      id: "1",
      title: "Todo 1",
      description: option.Some("First todo"),
      priority: shared.High,
      completed: True,
    ),
    shared.Todo(
      id: "2",
      title: "Todo 2",
      description: option.Some("Second todo"),
      priority: shared.Medium,
      completed: False,
    ),
    shared.Todo(
      id: "3",
      title: "Todo 3",
      description: option.Some("Third todo"),
      priority: shared.Low,
      completed: True,
    ),
  ]

  let result = filter.filter_todos(todos, filter.All)

  should.equal(list.length(result), 3)
  // Verify order is preserved
  should.equal(list.first(result), Ok(list.first(todos) |> should.be_ok))
}

// Acceptance: Given filter=Active, return only todos with completed=False
pub fn filter_active_returns_only_incomplete_todos_test() {
  let todos = [
    shared.Todo(
      id: "1",
      title: "Todo 1",
      description: option.Some("First todo"),
      priority: shared.High,
      completed: True,
    ),
    shared.Todo(
      id: "2",
      title: "Todo 2",
      description: option.Some("Second todo"),
      priority: shared.Medium,
      completed: False,
    ),
    shared.Todo(
      id: "3",
      title: "Todo 3",
      description: option.Some("Third todo"),
      priority: shared.Low,
      completed: True,
    ),
  ]

  let result = filter.filter_todos(todos, filter.Active)

  should.equal(list.length(result), 1)
  let first = list.first(result) |> should.be_ok
  should.equal(first.id, "2")
  should.equal(first.completed, False)
}

pub fn filter_active_excludes_completed_todos_test() {
  let todos = [
    shared.Todo(
      id: "1",
      title: "Todo 1",
      description: option.Some("First todo"),
      priority: shared.High,
      completed: True,
    ),
    shared.Todo(
      id: "2",
      title: "Todo 2",
      description: option.Some("Second todo"),
      priority: shared.Medium,
      completed: False,
    ),
  ]

  let result = filter.filter_todos(todos, filter.Active)

  list.any(result, fn(t) { t.completed })
  |> should.be_false
}

// Acceptance: Given filter=Completed, return only todos with completed=True
pub fn filter_completed_returns_only_completed_todos_test() {
  let todos = [
    shared.Todo(
      id: "1",
      title: "Todo 1",
      description: option.Some("First todo"),
      priority: shared.High,
      completed: True,
    ),
    shared.Todo(
      id: "2",
      title: "Todo 2",
      description: option.Some("Second todo"),
      priority: shared.Medium,
      completed: False,
    ),
    shared.Todo(
      id: "3",
      title: "Todo 3",
      description: option.Some("Third todo"),
      priority: shared.Low,
      completed: True,
    ),
  ]

  let result = filter.filter_todos(todos, filter.Completed)

  should.equal(list.length(result), 2)
  list.all(result, fn(t) { t.completed })
  |> should.be_true
}

pub fn filter_completed_excludes_active_todos_test() {
  let todos = [
    shared.Todo(
      id: "1",
      title: "Todo 1",
      description: option.Some("First todo"),
      priority: shared.High,
      completed: True,
    ),
    shared.Todo(
      id: "2",
      title: "Todo 2",
      description: option.Some("Second todo"),
      priority: shared.Medium,
      completed: False,
    ),
  ]

  let result = filter.filter_todos(todos, filter.Completed)

  list.any(result, fn(t) { bool.negate(t.completed) })
  |> should.be_false
}

// Acceptance: Empty list returns empty regardless of filter
pub fn filter_all_empty_list_returns_empty_test() {
  let todos: List(shared.Todo) = []

  let result = filter.filter_todos(todos, filter.All)

  should.equal(result, [])
}

pub fn filter_active_empty_list_returns_empty_test() {
  let todos: List(shared.Todo) = []

  let result = filter.filter_todos(todos, filter.Active)

  should.equal(result, [])
}

pub fn filter_completed_empty_list_returns_empty_test() {
  let todos: List(shared.Todo) = []

  let result = filter.filter_todos(todos, filter.Completed)

  should.equal(result, [])
}

// Edge case: Filter preserves original todo item structure
pub fn filter_preserves_todo_structure_test() {
  let item = shared.Todo(
    id: "1",
    title: "Test Todo",
    description: option.Some("A description"),
    priority: shared.High,
    completed: False,
  )
  let todos = [item]

  let result = filter.filter_todos(todos, filter.All)

  let first = list.first(result) |> should.be_ok
  should.equal(first.id, "1")
  should.equal(first.title, "Test Todo")
  should.equal(first.description, option.Some("A description"))
  should.equal(first.priority, shared.High)
  should.equal(first.completed, False)
}

// Edge case: Filter does not mutate original list
pub fn filter_does_not_mutate_original_list_test() {
  let todos = [
    shared.Todo(
      id: "1",
      title: "Todo 1",
      description: option.Some("First"),
      priority: shared.High,
      completed: True,
    ),
    shared.Todo(
      id: "2",
      title: "Todo 2",
      description: option.Some("Second"),
      priority: shared.Medium,
      completed: False,
    ),
  ]

  let _ = filter.filter_todos(todos, filter.Active)

  // Original list should be unchanged
  should.equal(list.length(todos), 2)
  let first = list.first(todos) |> should.be_ok
  should.equal(first.id, "1")
  should.equal(first.completed, True)
}

// Edge case: Large list filtering performance
pub fn filter_all_large_list_performance_test() {
  let todos = list.repeat(
    shared.Todo(
      id: "1",
      title: "Todo",
      description: option.Some("Desc"),
      priority: shared.Medium,
      completed: False,
    ),
    1000,
  )

  let result = filter.filter_todos(todos, filter.All)

  should.equal(list.length(result), 1000)
}

pub fn filter_active_large_list_returns_half_test() {
  // Create a list with 500 completed and 500 active todos
  let completed_todos = list.repeat(
    shared.Todo(
      id: "1",
      title: "Todo",
      description: option.Some("Desc"),
      priority: shared.Medium,
      completed: True,
    ),
    500,
  )
  let active_todos = list.repeat(
    shared.Todo(
      id: "2",
      title: "Todo",
      description: option.Some("Desc"),
      priority: shared.Medium,
      completed: False,
    ),
    500,
  )
  let todos = list.append(completed_todos, active_todos)

  let result = filter.filter_todos(todos, filter.Active)

  should.equal(list.length(result), 500)
}

pub fn filter_completed_large_list_returns_half_test() {
  // Create a list with 500 completed and 500 active todos
  let completed_todos = list.repeat(
    shared.Todo(
      id: "1",
      title: "Todo",
      description: option.Some("Desc"),
      priority: shared.Medium,
      completed: True,
    ),
    500,
  )
  let active_todos = list.repeat(
    shared.Todo(
      id: "2",
      title: "Todo",
      description: option.Some("Desc"),
      priority: shared.Medium,
      completed: False,
    ),
    500,
  )
  let todos = list.append(completed_todos, active_todos)

  let result = filter.filter_todos(todos, filter.Completed)

  should.equal(list.length(result), 500)
}
