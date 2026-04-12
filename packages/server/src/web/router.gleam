import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/string
import shared
import todo_store.{type Store}
import web/server.{type Request, type Response}
import web/static

pub fn make_handler(store: Store) -> fn(Request) -> Response {
  fn(request: Request) { route(request, store) }
}

fn route(request: Request, store: Store) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "POST", "/api/todos" -> create_todo_handler(request, store)
    "GET", "/api/todos" -> list_todos_handler(request, store)
    "GET", path -> route_get(path)
    _, _ -> not_found()
  }
}

fn route_get(path: String) -> Response {
  case string.starts_with(path, "/static/") {
    True -> static.serve(path)
    False -> not_found()
  }
}

fn health_handler() -> Response {
  server.json_response(
    200,
    json.object([#("status", json.string("ok"))])
    |> json.to_string,
  )
}

fn not_found() -> Response {
  server.json_response(
    404,
    json.object([#("error", json.string("Not found"))])
    |> json.to_string,
  )
}

/// Handler for POST /api/todos - creates a new todo
fn create_todo_handler(request: Request, store: Store) -> Response {
  // Parse JSON body
  let input_decoder = {
    use title <- decode.optional_field("title", None, decode.optional(decode.string))
    use description <- decode.optional_field("description", None, decode.optional(decode.string))
    use priority <- decode.optional_field("priority", None, decode.optional(decode.string))
    use completed <- decode.optional_field("completed", None, decode.optional(decode.bool))

    decode.success(#(title, description, priority, completed))
  }

  case json.parse(from: request.body, using: input_decoder) {
    Ok(#(maybe_title, maybe_description, maybe_priority, maybe_completed)) -> {
      // Validate title
      let title_validation = case maybe_title {
        None -> Error("Title is required")
        Some(title) -> {
          let trimmed = string.trim(title)
          case string.is_empty(trimmed) {
            True -> Error("Title is required")
            False -> {
              case string.length(trimmed) > 200 {
                True -> Error("Title must not exceed 200 characters")
                False -> Ok(trimmed)
              }
            }
          }
        }
      }

      case title_validation {
        Error(msg) -> validation_error_response(msg)
        Ok(trimmed_title) -> {
          // Parse and validate priority
          let priority_result = case maybe_priority {
            None -> Ok(shared.Medium)
            Some(priority_str) -> {
              case string.lowercase(priority_str) {
                "low" -> Ok(shared.Low)
                "medium" -> Ok(shared.Medium)
                "high" -> Ok(shared.High)
                _ -> Error("Priority must be one of: low, medium, high")
              }
            }
          }

          case priority_result {
            Error(msg) -> validation_error_response(msg)
            Ok(priority) -> {
              // Determine completed (default to False)
              let completed = case maybe_completed {
                None -> False
                Some(c) -> c
              }

              // Create the todo
              case todo_store.create_todo(store, trimmed_title, maybe_description, priority, completed) {
                Ok(created_todo) -> {
                  server.json_response(201, todo_to_json(created_todo))
                }
                Error(error_msg) -> {
                  validation_error_response(error_msg)
                }
              }
            }
          }
        }
      }
    }
    Error(_) -> {
      validation_error_response("Invalid JSON payload")
    }
  }
}

/// Convert a Todo to JSON string
fn todo_to_json(item: shared.Todo) -> String {
  json.object([
    #("id", json.string(item.id)),
    #("title", json.string(item.title)),
    #("description", case item.description {
      Some(desc) -> json.string(desc)
      None -> json.null()
    }),
    #("priority", json.string(priority_to_string(item.priority))),
    #("completed", json.bool(item.completed)),
    #("created_at", json.string(item.created_at)),
    #("updated_at", json.string(item.updated_at)),
  ])
  |> json.to_string()
}

/// Convert priority to string
fn priority_to_string(priority: shared.Priority) -> String {
  case priority {
    shared.Low -> "low"
    shared.Medium -> "medium"
    shared.High -> "high"
  }
}

/// Return a 422 validation error response
fn validation_error_response(message: String) -> Response {
  server.json_response(
    422,
    json.object([#("error", json.string(message))])
    |> json.to_string,
  )
}

/// Handler for GET /api/todos - lists all todos
fn list_todos_handler(_request: Request, store: Store) -> Response {
  let all_todos = todo_store.get_all_todos(store)
  let todos_json = json.array(all_todos, of: fn(item) {
    json.object([
      #("id", json.string(item.id)),
      #("title", json.string(item.title)),
      #("description", case item.description {
        Some(desc) -> json.string(desc)
        None -> json.null()
      }),
      #("priority", json.string(priority_to_string(item.priority))),
      #("completed", json.bool(item.completed)),
      #("created_at", json.string(item.created_at)),
      #("updated_at", json.string(item.updated_at)),
    ])
  })

  server.json_response(
    200,
    json.to_string(todos_json),
  )
}
