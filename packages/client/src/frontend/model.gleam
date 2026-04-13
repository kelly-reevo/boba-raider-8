/// Application state for todo management

import gleam/option.{type Option, None}

/// Filter options for todo list
pub type Filter {
  All
  Active
  Completed
}

/// Todo item structure matching the API
pub type Todo {
  Todo(
    id: String,
    title: String,
    description: Option(String),
    priority: String,
    completed: Bool,
    created_at: String,
    updated_at: String,
  )
}

/// Form state for creating new todos
pub type FormState {
  FormState(
    title: String,
    description: String,
    priority: String,
  )
}

/// Application model containing all state
pub type Model {
  Model(
    todos: List(Todo),
    filter: Filter,
    loading: Bool,
    toggling_id: String,
    error: Option(String),
    form: FormState,
  )
}

/// Create default initial model
pub fn default() -> Model {
  Model(
    todos: [],
    filter: All,
    loading: True,
    toggling_id: "",
    error: None,
    form: FormState("", "", "medium"),
  )
}

/// Filter todos based on current filter setting
pub fn filter_todos(model: Model) -> List(Todo) {
  case model.filter {
    All -> model.todos
    Active -> filter_active(model.todos)
    Completed -> filter_completed(model.todos)
  }
}

fn filter_active(todos: List(Todo)) -> List(Todo) {
  case todos {
    [] -> []
    [item, ..rest] -> {
      case item.completed {
        False -> [item, ..filter_active(rest)]
        True -> filter_active(rest)
      }
    }
  }
}

fn filter_completed(todos: List(Todo)) -> List(Todo) {
  case todos {
    [] -> []
    [item, ..rest] -> {
      case item.completed {
        True -> [item, ..filter_completed(rest)]
        False -> filter_completed(rest)
      }
    }
  }
}

/// Get display name for current filter
pub fn filter_name(filter: Filter) -> String {
  case filter {
    All -> "all"
    Active -> "active"
    Completed -> "completed"
  }
}
