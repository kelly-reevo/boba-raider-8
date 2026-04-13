import shared.{type Todo}

/// Filter options for todo list
pub type Filter {
  All
  Active
  Completed
}

/// Application state
pub type Model {
  Model(
    todos: List(Todo),
    filter: Filter,
    loading: Bool,
    error: String,
  )
}

pub fn default() -> Model {
  Model(todos: [], filter: All, loading: False, error: "")
}

/// Apply current filter to todos - client-side only, no API call
pub fn get_filtered_todos(model: Model) -> List(Todo) {
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
      let filtered = filter_active(rest)
      case item.completed {
        False -> [item, ..filtered]
        True -> filtered
      }
    }
  }
}

fn filter_completed(todos: List(Todo)) -> List(Todo) {
  case todos {
    [] -> []
    [item, ..rest] -> {
      let filtered = filter_completed(rest)
      case item.completed {
        True -> [item, ..filtered]
        False -> filtered
      }
    }
  }
}
