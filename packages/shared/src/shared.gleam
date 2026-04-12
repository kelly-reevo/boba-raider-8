/// Shared types and functions for boba-raider-8

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

/// Todo type for the shared package
/// Used across both server and client
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
