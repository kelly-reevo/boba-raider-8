/// Application state for the todo app
/// Extended MVU model with server-authoritative patterns

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
    form_description: String,
    form_priority: Priority,
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
    form_description: "",
    form_priority: shared.Medium,
    loading: False,
    error: "",
    delete_confirming_id: None,
  )
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

/// Filter todos based on current filter state
pub fn filter_todos(model: Model) -> List(Todo) {
  case model.filter {
    All -> model.todos
    Active -> filter_active(model.todos, [])
    Completed -> filter_completed(model.todos, [])
  }
}

fn filter_active(todos: List(Todo), acc: List(Todo)) -> List(Todo) {
  case todos {
    [] -> acc |> reverse_list([])
    [first, ..rest] -> {
      case first.completed {
        False -> filter_active(rest, [first, ..acc])
        True -> filter_active(rest, acc)
      }
    }
  }
}

fn filter_completed(todos: List(Todo), acc: List(Todo)) -> List(Todo) {
  case todos {
    [] -> acc |> reverse_list([])
    [first, ..rest] -> {
      case first.completed {
        True -> filter_completed(rest, [first, ..acc])
        False -> filter_completed(rest, acc)
      }
    }
  }
}

fn reverse_list(list: List(a), acc: List(a)) -> List(a) {
  case list {
    [] -> acc
    [first, ..rest] -> reverse_list(rest, [first, ..acc])
  }
}
