/// Shared types and functions for boba-raider-8

import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}

pub type AppError {
  NotFound(String)
  InvalidInput(String)
  InternalError(String)
}

/// Convert an error to a human-readable message
pub fn error_message(error: AppError) -> String {
  case error {
    NotFound(msg) -> "Not found: " <> msg
    InvalidInput(msg) -> "Invalid input: " <> msg
    InternalError(msg) -> "Internal error: " <> msg
  }
}

/// Todo type representing a task
pub type Todo {
  Todo(
    id: String,
    title: String,
    description: String,
    completed: Bool,
    created_at: Int,
    updated_at: Int,
  )
}

/// Input type for creating a new todo
pub type CreateTodoInput {
  CreateTodoInput(
    title: String,
    description: String,
  )
}

/// Input type for updating an existing todo
/// All fields are optional to support partial updates
pub type UpdateTodoInput {
  UpdateTodoInput(
    title: Option(String),
    description: Option(String),
    completed: Option(Bool),
  )
}

/// Create a new Todo with the given id and title
/// Description defaults to empty string, completed defaults to False
/// Timestamps are set to the current time
pub fn new_todo(id: String, title: String) -> Todo {
  let now = 0
  Todo(
    id: id,
    title: title,
    description: "",
    completed: False,
    created_at: now,
    updated_at: now,
  )
}

/// Convert a single Todo to JSON
pub fn todo_to_json(item: Todo) -> json.Json {
  json.object([
    #("id", json.string(item.id)),
    #("title", json.string(item.title)),
    #("description", json.string(item.description)),
    #("completed", json.bool(item.completed)),
    #("created_at", json.int(item.created_at)),
    #("updated_at", json.int(item.updated_at)),
  ])
}

/// Convert a list of Todos to JSON array
pub fn todos_to_json(todos: List(Todo)) -> json.Json {
  json.array(todos, todo_to_json)
}

/// Encode a Todo to JSON (alias for todo_to_json)
pub fn encode(item: Todo) -> json.Json {
  todo_to_json(item)
}

/// Decode JSON string into a Todo
pub fn decode(json_string: String) -> Result(Todo, AppError) {
  let decoder = {
    use id <- decode.field("id", decode.string)
    use title <- decode.field("title", decode.string)
    use description <- decode.field("description", decode.string)
    use completed <- decode.field("completed", decode.bool)
    use created_at <- decode.field("created_at", decode.int)
    use updated_at <- decode.field("updated_at", decode.int)
    decode.success(Todo(id:, title:, description:, completed:, created_at:, updated_at:))
  }

  case json.parse(json_string, decoder) {
    Ok(item) -> Ok(item)
    Error(json_decode_errors) -> {
      // Extract error information from json.DecodeError
      let error_message = case json_decode_errors {
        json.UnableToDecode(decode_errors) -> {
          // Extract the first error field name
          let first_error = case decode_errors {
            [err, ..] -> err
            [] -> decode.DecodeError(expected: "", found: "", path: [])
          }
          // Get the field name from the path
          let field_name = case first_error.path {
            [field, ..] -> field
            [] -> "unknown"
          }
          "Missing or invalid field: " <> field_name
        }
        _ -> "Invalid JSON"
      }
      Error(InvalidInput(error_message))
    }
  }
}
