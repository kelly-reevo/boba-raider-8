import gleam/option.{type Option}
import gleam/string

pub type TodoInput {
  TodoInput(
    title: String,
    description: Option(String),
    priority: String,
  )
}

pub fn validate(
  title: String,
  description: Option(String),
  priority: String,
) -> Result(TodoInput, List(String)) {
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
    [] -> Ok(TodoInput(title:, description:, priority:))
    _ -> Error(errors)
  }
}
