import gleam/list
import gleam/option.{type Option}
import gleam/string
import shared.{type Priority, High, Medium, Low}

/// Partial update type for todos
pub type TodoPatch {
  TodoPatch(
    title: Option(String),
    description: Option(String),
    priority: Option(Priority),
    completed: Option(Bool),
  )
}

/// Input type for todo creation with Priority type
pub type TodoInput {
  TodoInput(
    title: String,
    description: Option(String),
    priority: Priority,
  )
}

/// Simple input type with string priority (for client communication)
pub type TodoInputRaw {
  TodoInputRaw(
    title: String,
    description: Option(String),
    priority: String,
  )
}

/// Validate todo input and return TodoInput or list of error strings
pub fn validate_todo_input(
  title: String,
  description: Option(String),
  priority: String,
) -> Result(TodoInput, List(String)) {
  // Collect validation errors
  let title_errors = case string.length(title) > 0 {
    False -> ["Title cannot be empty"]
    True ->
      case string.length(title) > 200 {
        True -> ["title too long"]
        False -> []
      }
  }

  let desc_errors = case description {
    option.Some(desc) ->
      case string.length(desc) > 1000 {
        True -> ["description too long"]
        False -> []
      }
    option.None -> []
  }

  let priority_error = case parse_priority(priority) {
    Error(_) -> ["Invalid priority"]
    Ok(_) -> []
  }

  let all_errors = list.flatten([title_errors, desc_errors, priority_error])

  case all_errors {
    [] -> {
      let assert Ok(prio) = parse_priority(priority)
      Ok(TodoInput(title: title, description: description, priority: prio))
    }
    errors -> Error(errors)
  }
}

/// Simple validation returning string-based priority (for client use)
pub fn validate(
  title: String,
  description: Option(String),
  priority: String,
) -> Result(TodoInputRaw, List(String)) {
  let errors = []

  let errors = case string.trim(title) {
    "" -> ["title is required", ..errors]
    t ->
      case string.length(t) > 200 {
        True -> ["title too long", ..errors]
        False -> errors
      }
  }

  let errors = case description {
    option.Some(desc) ->
      case string.length(desc) > 1000 {
        True -> ["description too long", ..errors]
        False -> errors
      }
    option.None -> errors
  }

  let errors = case priority {
    "low" -> errors
    "medium" -> errors
    "high" -> errors
    _ -> ["invalid priority", ..errors]
  }

  case errors {
    [] -> Ok(TodoInputRaw(title:, description:, priority:))
    _ -> Error(errors)
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
