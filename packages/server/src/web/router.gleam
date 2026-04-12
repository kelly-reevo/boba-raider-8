import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import shared.{type Todo, type UpdateTodoInput}
import todo_store.{type Store}
import web/error_middleware
import web/server.{type Request, type Response, json_response}
import web/static

/// Create the main request handler with error handling middleware
pub fn make_handler(store: Store) -> fn(Request) -> Response {
  let base_handler = fn(request: Request) { route(request, store) }
  error_middleware.with_error_handling(base_handler)
}

fn route(request: Request, store: Store) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "GET", "/api/todos" -> list_todos_handler(store, request)
    "GET", path -> route_get_todo(path, store)
    "POST", "/api/todos" -> create_todo_handler(request, store)
    "PATCH", path -> route_patch_todo(path, request, store)
    "DELETE", path -> route_delete_todo(path, store)
    _, _ -> not_found()
  }
}

fn route_get(path: String) -> Response {
  case string.starts_with(path, "/static/") {
    True -> static.serve(path)
    False -> not_found()
  }
}

fn route_get_todo(path: String, store: Store) -> Response {
  case string.starts_with(path, "/api/todos/") {
    True -> {
      // Extract ID after "/api/todos/" prefix
      let id = string.slice(path, at_index: 11, length: string.length(path) - 11)
      get_todo_handler(id, store)
    }
    False -> route_get(path)
  }
}

fn route_patch_todo(path: String, request: Request, store: Store) -> Response {
  case string.starts_with(path, "/api/todos/") {
    True -> {
      // Extract ID after "/api/todos/" prefix
      let id = string.slice(path, at_index: 11, length: string.length(path) - 11)
      update_todo_handler(request, id, store)
    }
    False -> not_found()
  }
}

fn route_delete_todo(path: String, store: Store) -> Response {
  case string.starts_with(path, "/api/todos/") {
    True -> {
      // Extract ID after "/api/todos/" prefix
      let id = string.slice(path, at_index: 11, length: string.length(path) - 11)
      delete_todo_handler(id, store)
    }
    False -> not_found()
  }
}

/// Parse query string and return dict of parameters
fn parse_query_params(path: String) -> Dict(String, String) {
  case string.split(path, "?") {
    [_, query_string] -> parse_params(query_string)
    _ -> dict.new()
  }
}

/// Parse a query string into key-value pairs
fn parse_params(query_string: String) -> Dict(String, String) {
  case string.is_empty(query_string) {
    True -> dict.new()
    False -> {
      let pairs = string.split(query_string, "&")
      list.fold(pairs, dict.new(), fn(acc, pair) {
        case string.split(pair, "=") {
          [key, value] -> dict.insert(acc, key, value)
          _ -> acc
        }
      })
    }
  }
}

/// Get filter value from query params, default to "all"
fn get_filter_param(params: Dict(String, String)) -> String {
  case dict.get(params, "filter") {
    Ok(filter) -> filter
    Error(_) -> "all"
  }
}

/// Filter todos based on completion status
fn filter_todos(todos: List(Todo), filter: String) -> List(Todo) {
  case filter {
    "active" -> list.filter(todos, fn(t) { !t.completed })
    "completed" -> list.filter(todos, fn(t) { t.completed })
    _ -> todos
  }
}

fn health_handler() -> Response {
  json_response(
    200,
    json.object([#("status", json.string("ok"))])
    |> json.to_string,
  )
}

fn not_found() -> Response {
  json_response(
    404,
    json.object([#("error", json.string("Not found"))])
    |> json.to_string,
  )
}

fn list_todos_handler(store: Store, request: Request) -> Response {
  let params = parse_query_params(request.path)
  let filter = get_filter_param(params)
  let todos = todo_store.get_all_todos(store)
  let filtered = filter_todos(todos, filter)
  json_response(200, todos_to_json(filtered))
}

fn get_todo_handler(id: String, store: Store) -> Response {
  case todo_store.get_todo(store, id) {
    Some(item) -> json_response(200, todo_to_json(item))
    None -> not_found()
  }
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
                  json_response(201, todo_to_json(created_todo))
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

fn update_todo_handler(request: Request, id: String, store: Store) -> Response {
  // Parse request body
  let decoder = {
    use title <- decode.field("title", decode.optional(decode.string))
    use description <- decode.field("description", decode.optional(decode.string))
    use completed <- decode.field("completed", decode.optional(decode.bool))
    decode.success(shared.UpdateTodoInput(
      title: title,
      description: description,
      completed: completed,
    ))
  }

  case json.parse(from: request.body, using: decoder) {
    Ok(input) -> {
      case todo_store.update_todo(store, id, input) {
        Ok(item) -> json_response(200, todo_to_json(item))
        Error(_) -> not_found()
      }
    }
    Error(_) -> {
      json_response(
        400,
        json.object([#("error", json.string("Invalid request body"))])
        |> json.to_string,
      )
    }
  }
}

fn delete_todo_handler(id: String, store: Store) -> Response {
  case todo_store.delete_todo(store, id) {
    Ok(_) -> json_response(204, "")
    Error(_) -> not_found()
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
  json_response(
    422,
    json.object([#("error", json.string(message))])
    |> json.to_string(),
  )
}

/// Convert a list of Todos to JSON array
fn todos_to_json(todos: List(Todo)) -> String {
  json.array(todos, fn(item) {
    json.object([
      #("id", json.string(item.id)),
      #("title", json.string(item.title)),
      #("description", case item.description {
        Some(d) -> json.string(d)
        None -> json.null()
      }),
      #("priority", json.string(priority_to_string(item.priority))),
      #("completed", json.bool(item.completed)),
      #("created_at", json.string(item.created_at)),
      #("updated_at", json.string(item.updated_at)),
    ])
  })
  |> json.to_string()
}
