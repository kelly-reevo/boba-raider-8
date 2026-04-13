import gleeunit
import gleeunit/should
import frontend/model
import shared

pub fn main() {
  gleeunit.main()
}

/// Test that default model has empty todos and All filter
pub fn default_model_test() {
  let m = model.default()
  m.todos
  |> should.equal([])

  m.filter
  |> should.equal(model.All)
}

/// Test empty state message for All filter
pub fn empty_message_all_filter_test() {
  let m = model.default()
  model.get_empty_message(m)
  |> should.equal("No todos yet. Add your first todo above!")
}

/// Test empty state message for Active filter
pub fn empty_message_active_filter_test() {
  let m = model.Model(..model.default(), filter: model.Active)
  model.get_empty_message(m)
  |> should.equal("No active todos")
}

/// Test empty state message for Completed filter
pub fn empty_message_completed_filter_test() {
  let m = model.Model(..model.default(), filter: model.Completed)
  model.get_empty_message(m)
  |> should.equal("No completed todos")
}

/// Test is_filtered_empty returns true when no todos
pub fn is_filtered_empty_true_test() {
  let m = model.default()
  model.is_filtered_empty(m)
  |> should.equal(True)
}

/// Test is_filtered_empty returns false when todos exist
pub fn is_filtered_empty_false_test() {
  let todo_item = shared.Todo(
    id: "1",
    title: "Test",
    description: shared.none(),
    priority: shared.Medium,
    completed: False,
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  )
  let m = model.Model(..model.default(), todos: [todo_item])
  model.is_filtered_empty(m)
  |> should.equal(False)
}

/// Test Active filter hides completed todos
pub fn active_filter_hides_completed_test() {
  let active_todo = shared.Todo(
    id: "1",
    title: "Active",
    description: shared.none(),
    priority: shared.Medium,
    completed: False,
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  )
  let completed_todo = shared.Todo(
    id: "2",
    title: "Completed",
    description: shared.none(),
    priority: shared.Medium,
    completed: True,
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  )
  let m = model.Model(
    ..model.default(),
    todos: [active_todo, completed_todo],
    filter: model.Active,
  )

  model.get_filtered_todos(m)
  |> should.equal([active_todo])
}

/// Test Completed filter shows only completed todos
pub fn completed_filter_shows_completed_test() {
  let active_todo = shared.Todo(
    id: "1",
    title: "Active",
    description: shared.none(),
    priority: shared.Medium,
    completed: False,
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  )
  let completed_todo = shared.Todo(
    id: "2",
    title: "Completed",
    description: shared.none(),
    priority: shared.Medium,
    completed: True,
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  )
  let m = model.Model(
    ..model.default(),
    todos: [active_todo, completed_todo],
    filter: model.Completed,
  )

  model.get_filtered_todos(m)
  |> should.equal([completed_todo])
}

/// Test All filter shows all todos
pub fn all_filter_shows_all_test() {
  let todo1 = shared.Todo(
    id: "1",
    title: "First",
    description: shared.none(),
    priority: shared.Medium,
    completed: False,
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  )
  let todo2 = shared.Todo(
    id: "2",
    title: "Second",
    description: shared.none(),
    priority: shared.Medium,
    completed: True,
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  )
  let m = model.Model(..model.default(), todos: [todo1, todo2], filter: model.All)

  model.get_filtered_todos(m)
  |> should.equal([todo1, todo2])
}
