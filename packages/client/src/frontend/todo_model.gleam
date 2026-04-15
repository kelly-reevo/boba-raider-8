/// Todo domain model with extensible state management

/// Core todo item type
pub type Todo {
  Todo(id: String, title: String, completed: Bool)
}

/// Filter state for todo list views
pub type Filter {
  All
  Active
  Completed
}

/// Extended model supporting todo list with counter
pub type TodoModel {
  TodoModel(
    todos: List(Todo),
    filter: Filter,
    active_count: Int,
    error: String,
    loading: Bool,
  )
}

/// Create default empty model
pub fn default() -> TodoModel {
  TodoModel(todos: [], filter: All, active_count: 0, error: "", loading: False)
}

/// Calculate active count from todos list
pub fn calculate_active_count(todos: List(Todo)) -> Int {
  todos
  |> filter_active
  |> length
}

/// Filter todos by active status
fn filter_active(todos: List(Todo)) -> List(Todo) {
  case todos {
    [] -> []
    [first, ..rest] ->
      case first.completed {
        False -> [first, ..filter_active(rest)]
        True -> filter_active(rest)
      }
  }
}

/// List length helper
fn length(list: List(a)) -> Int {
  case list {
    [] -> 0
    [_, ..rest] -> 1 + length(rest)
  }
}

/// Toggle a todo's completed status by id
pub fn toggle_todo(todos: List(Todo), id: String) -> List(Todo) {
  case todos {
    [] -> []
    [first, ..rest] ->
      case first.id == id {
        True -> [Todo(..first, completed: !first.completed), ..rest]
        False -> [first, ..toggle_todo(rest, id)]
      }
  }
}

/// Get single todo by id
pub fn get_todo(todos: List(Todo), id: String) -> Result(Todo, Nil) {
  case todos {
    [] -> Error(Nil)
    [first, ..rest] ->
      case first.id == id {
        True -> Ok(first)
        False -> get_todo(rest, id)
      }
  }
}

/// Filter todos based on current filter
pub fn filter_todos(todos: List(Todo), filter: Filter) -> List(Todo) {
  case filter {
    All -> todos
    Active -> filter_by_completed(todos, False)
    Completed -> filter_by_completed(todos, True)
  }
}

fn filter_by_completed(todos: List(Todo), completed: Bool) -> List(Todo) {
  case todos {
    [] -> []
    [first, ..rest] ->
      case first.completed == completed {
        True -> [first, ..filter_by_completed(rest, completed)]
        False -> filter_by_completed(rest, completed)
      }
  }
}

/// Format active count for display (singular/plural)
pub fn format_active_count(count: Int) -> String {
  case count {
    1 -> "1 item left"
    n -> int_to_string(n) <> " items left"
  }
}

fn int_to_string(n: Int) -> String {
  case n {
    0 -> "0"
    i if i < 0 -> "-" <> int_to_string(-i)
    i -> int_to_string_positive(i)
  }
}

fn int_to_string_positive(n: Int) -> String {
  case n {
    0 -> ""
    i -> int_to_string_positive(i / 10) <> digit_to_string(i % 10)
  }
}

fn digit_to_string(d: Int) -> String {
  case d {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    6 -> "6"
    7 -> "7"
    8 -> "8"
    9 -> "9"
    _ -> ""
  }
}
