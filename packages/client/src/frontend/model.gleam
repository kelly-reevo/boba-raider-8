/// Application state for the todo app
/// Extended MVU model with server-authoritative patterns

import gleam/list
import gleam/option.{type Option, None}
import shared.{type Priority, type Todo}

/// Filter variants for todo list filtering
pub type FilterState {
  All
  Active
  Completed
}

/// Application model containing todos, filter state, form fields, loading, and error
pub type Model {
  Model(
    // Todo list state
    todos: List(Todo),
    filter: FilterState,
    // Form fields for creating todos
    form_title: String,
    form_description: Option(String),
    form_priority: String,
    // UI state
    loading: Bool,
    error: String,
    // Delete confirmation state (two-phase delete)
    delete_confirming_id: Option(String),
  )
}

/// Default empty model state
pub fn default() -> Model {
  Model(
    todos: [],
    filter: All,
    form_title: "",
    form_description: None,
    form_priority: "medium",
    loading: False,
    error: "",
    delete_confirming_id: None,
  )
}

/// Empty model helper for tests
pub fn empty_model() -> Model {
  default()
}

/// Check if there are any todos
pub fn has_todos(model: Model) -> Bool {
  case model.todos {
    [] -> False
    _ -> True
  }
}

/// Get count of active (non-completed) todos
pub fn active_count(model: Model) -> Int {
  do_count_active(model.todos, 0)
}

fn do_count_active(todos: List(Todo), acc: Int) -> Int {
  case todos {
    [] -> acc
    [first, ..rest] -> {
      let new_acc = case first.completed {
        False -> acc + 1
        True -> acc
      }
      do_count_active(rest, new_acc)
    }
  }
}

/// Filter a list of todos based on the filter state
/// - All: returns all todos regardless of completion status
/// - Active: returns only todos with completed=False
/// - Completed: returns only todos with completed=True
pub fn apply_filter(todos: List(Todo), filter_state: FilterState) -> List(Todo) {
  case filter_state {
    All -> todos
    Active -> list.filter(todos, fn(t) { !t.completed })
    Completed -> list.filter(todos, fn(t) { t.completed })
  }
}

/// Filter todos based on current model's filter state
pub fn filter_todos(model: Model) -> List(Todo) {
  apply_filter(model.todos, model.filter)
}
