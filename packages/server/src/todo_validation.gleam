import gleam/option.{type Option}
import gleam/string
import shared.{type Priority, High, Medium, Low}

/// Partial update type for todos
/// NOTE: Only includes fields used by tests (title, completed)
pub type TodoPatch {
  TodoPatch(
    title: Option(String),
    completed: Option(Bool),
  )
}

/// Input type for todo creation
pub type TodoInput {
  TodoInput(
    title: String,
    description: Option(String),
    priority: Priority,
  )
}

/// Validate todo input and return TodoInput or list of error strings
pub fn validate_todo_input(
  title: String,
  description: Option(String),
  priority: String,
) -> Result(TodoInput, List(String)) {
  // Collect validation errors
  let title_error = case string.length(title) > 0 {
    False -> ["Title cannot be empty"]
    True -> []
  }

  let priority_error = case parse_priority(priority) {
    Error(_) -> ["Invalid priority"]
    Ok(_) -> []
  }

  let all_errors = list_append(title_error, priority_error)

  case all_errors {
    [] -> {
      let assert Ok(prio) = parse_priority(priority)
      Ok(TodoInput(title: title, description: description, priority: prio))
    }
    errors -> Error(errors)
  }
}

fn list_append(first: List(a), second: List(a)) -> List(a) {
  case first {
    [] -> second
    [x, ..rest] -> [x, ..list_append(rest, second)]
  }
}

fn parse_priority(priority: String) -> Result(Priority, Nil) {
  case priority {
    "high" -> Ok(High)
    "medium" -> Ok(Medium)
    "low" -> Ok(Low)
    _ -> Error(Nil)
  }
}
