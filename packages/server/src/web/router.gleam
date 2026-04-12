import gleam/dict.{type Dict}
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import gleam/otp/actor
import gleam/erlang/process.{type Subject}
import todo_store.{type TodoStore, type TodoItem}
import web/server.{type Request, type Response}
import web/static

// Store holder actor for test persistence across requests
type StoreHolderState {
  StoreHolderState(store: Option(TodoStore))
}

type StoreHolderMsg {
  GetStore(reply_to: Subject(TodoStore))
}

// FFI for store holder management
@external(erlang, "router_ffi", "get_store_holder")
fn get_store_holder() -> Result(Pid, Nil)

@external(erlang, "router_ffi", "set_store_holder")
fn set_store_holder(pid: Pid) -> Nil

type Pid

// Get or create the store actor
fn get_store_actor() -> Subject(StoreHolderMsg) {
  case get_store_holder() {
    Ok(pid) -> unsafe_cast_subject(pid)
    Error(_) -> {
      let actor_subject = start_store_actor()
      let _ = set_store_holder(unsafe_cast_pid(actor_subject))
      actor_subject
    }
  }
}

fn unsafe_cast_subject(pid: Pid) -> Subject(StoreHolderMsg) {
  unsafe_cast(pid)
}

fn unsafe_cast_pid(subject: Subject(StoreHolderMsg)) -> Pid {
  unsafe_cast(subject)
}

@external(erlang, "router_ffi", "unsafe_cast")
fn unsafe_cast(x: a) -> b

// Get the todo store (creates on first access)
fn get_or_create_store() -> TodoStore {
  let actor = get_store_actor()
  let reply = process.new_subject()
  process.send(actor, GetStore(reply))
  let assert Ok(store) = process.receive(reply, 5000)
  store
}

// Start the store holder actor
fn start_store_actor() -> Subject(StoreHolderMsg) {
  let initial_state = StoreHolderState(store: None)

  actor.new(initial_state)
  |> actor.on_message(handle_store_msg)
  |> actor.start()
  |> fn(result) {
    let assert Ok(started) = result
    started.data
  }
}

fn handle_store_msg(state: StoreHolderState, msg: StoreHolderMsg) {
  case msg {
    GetStore(reply_to) -> {
      case state.store {
        None -> {
          let store = case todo_store.start() {
            Ok(s) -> s
            Error(_) -> panic as "Failed to start todo store"
          }
          process.send(reply_to, store)
          actor.continue(StoreHolderState(store: Some(store)))
        }
        Some(store) -> {
          process.send(reply_to, store)
          actor.continue(state)
        }
      }
    }
  }
}

// Public handle_request for tests
pub fn handle_request(request: Request) -> Response {
  let store = get_or_create_store()
  route(request, store)
}

pub fn make_handler() -> fn(Request) -> Response {
  fn(request: Request) { handle_request(request) }
}

pub fn make_handler_with_store(store: TodoStore) -> fn(Request) -> Response {
  fn(request: Request) { route(request, store) }
}

fn route(request: Request, store: TodoStore) -> Response {
  // Extract path without query string for routing
  let path_only = case string.split(request.path, "?") {
    [path, _] -> path
    _ -> request.path
  }

  case request.method, path_only {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "GET", "/api/todos" -> list_todos_handler(request, store)
    "POST", "/api/todos" -> create_todo_handler(request, store)
    "PATCH", path -> {
      case string.starts_with(path, "/api/todos/") {
        True -> update_todo_handler(path, request, store)
        False -> not_found()
      }
    }
    "DELETE", path -> {
      case string.starts_with(path, "/api/todos/") {
        True -> delete_todo_handler(path, store)
        False -> not_found()
      }
    }
    "GET", path -> {
      case string.starts_with(path, "/api/todos/") {
        True -> get_todo_handler(path, store)
        False -> route_get(path)
      }
    }
    _, _ -> not_found()
  }
}

fn route_get(path: String) -> Response {
  case string.starts_with(path, "/static/") {
    True -> static.serve(path)
    False -> not_found()
  }
}

// Parse filter query parameter from request
fn get_filter_param(request: Request) -> String {
  // Extract query string from path
  case string.split(request.path, "?") {
    [_, query] -> {
      // Parse query parameters
      let params = parse_query_string(query)
      case dict.get(params, "filter") {
        Ok(value) -> string.lowercase(value)
        Error(_) -> "all"
      }
    }
    _ -> "all"
  }
}

// Parse query string into key-value pairs
fn parse_query_string(query: String) -> Dict(String, String) {
  let pairs = string.split(query, "&")
  list.fold(pairs, dict.new(), fn(acc, pair) {
    case string.split(pair, "=") {
      [key, value] -> dict.insert(acc, key, value)
      _ -> acc
    }
  })
}

// Filter todos based on completion status
fn filter_todos(todos: List(TodoItem), filter: String) -> List(TodoItem) {
  case filter {
    "active" -> list.filter(todos, fn(t) { !t.completed })
    "completed" -> list.filter(todos, fn(t) { t.completed })
    _ -> todos
  }
}

// Sort todos by created_at descending (newest first)
fn sort_todos_desc(todos: List(TodoItem)) -> List(TodoItem) {
  list.sort(todos, fn(a, b) {
    string.compare(b.created_at, a.created_at)
  })
}

// Convert TodoItem to JSON
fn todo_item_to_json(item: TodoItem) -> json.Json {
  let description_value = case item.description {
    Some(desc) -> json.string(desc)
    None -> json.null()
  }

  let priority_str = case item.priority {
    todo_store.Low -> "low"
    todo_store.Medium -> "medium"
    todo_store.High -> "high"
  }

  json.object([
    #("id", json.string(item.id)),
    #("title", json.string(item.title)),
    #("description", description_value),
    #("priority", json.string(priority_str)),
    #("completed", json.bool(item.completed)),
    #("created_at", json.string(item.created_at)),
    #("updated_at", json.string(item.updated_at)),
  ])
}

// Handler for GET /api/todos
fn list_todos_handler(request: Request, store: TodoStore) -> Response {
  let filter = get_filter_param(request)
  let todos = todo_store.list(store)
  let filtered = filter_todos(todos, filter)
  let sorted = sort_todos_desc(filtered)

  let json_array = json.array(sorted, todo_item_to_json)
  let body = json.to_string(json_array)

  server.json_response(200, body)
}

fn health_handler() -> Response {
  server.json_response(
    200,
    json.object([#("status", json.string("ok"))])
    |> json.to_string,
  )
}

// Create todo handler - POST /api/todos
fn create_todo_handler(request: Request, store: TodoStore) -> Response {
  case extract_create_fields(request.body) {
    Ok(#(title, description, priority_str)) -> {
      let priority = case priority_str {
        "low" -> todo_store.Low
        "high" -> todo_store.High
        _ -> todo_store.Medium
      }
      let timestamp = generate_iso_timestamp()
      let data = todo_store.TodoData(
        title: title,
        description: description,
        priority: priority,
        completed: False,
        created_at: timestamp,
        updated_at: timestamp,
      )
      let id = todo_store.insert(store, data)

      let response_item = TodoItem(
        id: id,
        title: title,
        description: description,
        priority: priority,
        completed: False,
        created_at: timestamp,
        updated_at: timestamp,
      )

      server.json_response(201, todo_item_to_json(response_item))
    }
    Error(_) -> {
      server.json_response(
        400,
        json.object([#("error", json.string("Invalid request"))]) |> json.to_string,
      )
    }
  }
}

// Extract fields from create request body
fn extract_create_fields(body: String) -> Result(#(String, Option(String), String), Nil) {
  let title = extract_json_string(body, "title")
  let description = extract_json_string(body, "description")
  let priority = extract_json_string(body, "priority")

  case title {
    Ok(Some(t)) -> {
      let desc = case description {
        Ok(Some(d)) -> Some(d)
        _ -> None
      }
      let prio = case priority {
        Ok(Some(p)) -> p
        _ -> "medium"
      }
      Ok(#(t, desc, prio))
    }
    _ -> Error(Nil)
  }
}

// Extract string value from JSON
fn extract_json_string(json_str: String, key: String) -> Result(Option(String), Nil) {
  let pattern = "\"" <> key <> "\":"
  case string.split(json_str, pattern) {
    [_, rest] | [_, rest, ..] -> {
      let trimmed = string.trim_start(rest)
      case trimmed {
        "null" <> _ -> Ok(None)
        _ -> {
          case string.starts_with(trimmed, "\"") {
            True -> {
              let after_quote = string.drop_start(trimmed, 1)
              case string.split(after_quote, "\"") {
                [value, ..] -> Ok(Some(value))
                _ -> Error(Nil)
              }
            }
            False -> Error(Nil)
          }
        }
      }
    }
    _ -> Error(Nil)
  }
}

// Get todo handler - GET /api/todos/:id
fn get_todo_handler(path: String, store: TodoStore) -> Response {
  let id = string.drop_start(path, 11) // Remove "/api/todos/"

  case is_valid_uuid(id) {
    True -> {
      case todo_store.get(store, id) {
        Some(item) -> {
          server.json_response(200, todo_item_to_json(item))
        }
        None -> {
          server.json_response(
            404,
            json.object([#("error", json.string("Todo not found"))]) |> json.to_string,
          )
        }
      }
    }
    False -> {
      server.json_response(
        404,
        json.object([#("error", json.string("Todo not found"))]) |> json.to_string,
      )
    }
  }
}

// Update todo handler - PATCH /api/todos/:id
fn update_todo_handler(path: String, request: Request, store: TodoStore) -> Response {
  let id = string.drop_start(path, 11) // Remove "/api/todos/"

  case is_valid_uuid(id) {
    True -> {
      case todo_store.get(store, id) {
        Some(existing) -> {
          case extract_update_fields(request.body, existing) {
            Ok(data) -> {
              case todo_store.update(store, id, data) {
                todo_store.UpdateOk -> {
                  case todo_store.get(store, id) {
                    Some(updated) -> server.json_response(200, todo_item_to_json(updated))
                    None -> server.json_response(
                      500,
                      json.object([#("error", json.string("Failed to retrieve updated todo"))]) |> json.to_string,
                    )
                  }
                }
                todo_store.NotFound -> server.json_response(
                  404,
                  json.object([#("error", json.string("Todo not found"))]) |> json.to_string,
                )
              }
            }
            Error(msg) -> server.json_response(
              422,
              json.object([#("error", json.string(msg))]) |> json.to_string,
            )
          }
        }
        None -> server.json_response(
          404,
          json.object([#("error", json.string("Todo not found"))]) |> json.to_string,
        )
      }
    }
    False -> server.json_response(
      404,
      json.object([#("error", json.string("Todo not found"))]) |> json.to_string,
    )
  }
}

// Extract update fields from request body
fn extract_update_fields(body: String, existing: TodoItem) -> Result(todo_store.TodoData, String) {
  let title = extract_json_string(body, "title")
  let description = extract_json_string(body, "description")
  let priority_result = extract_json_string(body, "priority")
  let completed_result = extract_json_bool(body, "completed")

  let new_title = case title {
    Ok(Some(t)) -> t
    _ -> existing.title
  }

  let new_description = case description {
    Ok(None) -> None
    Ok(Some(d)) -> Some(d)
    _ -> existing.description
  }

  let new_priority = case priority_result {
    Ok(Some("low")) -> todo_store.Low
    Ok(Some("high")) -> todo_store.High
    Ok(Some("medium")) -> todo_store.Medium
    Ok(None) -> existing.priority
    _ -> existing.priority
  }

  let new_completed = case completed_result {
    Ok(Some(c)) -> c
    _ -> existing.completed
  }

  Ok(todo_store.TodoData(
    title: new_title,
    description: new_description,
    priority: new_priority,
    completed: new_completed,
    created_at: existing.created_at,
    updated_at: generate_iso_timestamp(),
  ))
}

// Extract boolean value from JSON
fn extract_json_bool(json_str: String, key: String) -> Result(Option(Bool), Nil) {
  let pattern = "\"" <> key <> "\":"
  case string.split(json_str, pattern) {
    [_, rest] | [_, rest, ..] -> {
      let trimmed = string.trim_start(rest)
      case trimmed {
        "true" <> _ -> Ok(Some(True))
        "false" <> _ -> Ok(Some(False))
        "null" <> _ -> Ok(None)
        _ -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

// Delete todo handler - DELETE /api/todos/:id
fn delete_todo_handler(path: String, store: TodoStore) -> Response {
  let id = string.drop_start(path, 11) // Remove "/api/todos/"

  case is_valid_uuid(id) {
    True -> {
      case todo_store.delete(store, id) {
        todo_store.UpdateOk -> server.json_response(204, "")
        todo_store.NotFound -> server.json_response(
          404,
          json.object([#("error", json.string("Todo not found"))]) |> json.to_string,
        )
      }
    }
    False -> server.json_response(
      404,
      json.object([#("error", json.string("Todo not found"))]) |> json.to_string,
    )
  }
}

// Validate UUID format (8-4-4-4-12 hex characters)
fn is_valid_uuid(id: String) -> Bool {
  let parts = string.split(id, "-")
  case parts {
    [p1, p2, p3, p4, p5] -> {
      string.length(p1) == 8
      && string.length(p2) == 4
      && string.length(p3) == 4
      && string.length(p4) == 4
      && string.length(p5) == 12
      && is_hex_string(p1)
      && is_hex_string(p2)
      && is_hex_string(p3)
      && is_hex_string(p4)
      && is_hex_string(p5)
    }
    _ -> False
  }
}

// Check if string contains only hex characters
fn is_hex_string(s: String) -> Bool {
  let hex_chars = "0123456789abcdefABCDEF"
  string.to_graphemes(s)
  |> list.all(fn(c) { string.contains(hex_chars, c) })
}

// Generate ISO timestamp
fn generate_iso_timestamp() -> String {
  let seconds = system_time_seconds()
  format_iso8601(seconds)
}

// Get current time in seconds since epoch
@external(erlang, "erlang", "system_time")
fn system_time_seconds() -> Int

// Format seconds as ISO8601 UTC string: YYYY-MM-DDTHH:MM:SSZ
fn format_iso8601(seconds: Int) -> String {
  let days_since_epoch = seconds / 86_400
  let seconds_in_day = seconds % 86_400
  let year = 1970 + days_since_epoch / 365
  let day_of_year = days_since_epoch % 365
  let month = day_of_year / 30 + 1
  let day = day_of_year % 30 + 1
  let hour = seconds_in_day / 3600
  let minute = { seconds_in_day % 3600 } / 60
  let second = seconds_in_day % 60
  int_to_padded_string(year, 4) <> "-" <> int_to_padded_string(month, 2) <> "-" <> int_to_padded_string(day, 2) <> "T" <> int_to_padded_string(hour, 2) <> ":" <> int_to_padded_string(minute, 2) <> ":" <> int_to_padded_string(second, 2) <> "Z"
}

// Convert integer to zero-padded string
fn int_to_padded_string(n: Int, width: Int) -> String {
  let str = int_to_string(n)
  let len = string.length(str)
  case len >= width {
    True -> str
    False -> string.repeat("0", width - len) <> str
  }
}

@external(erlang, "erlang", "integer_to_binary")
fn int_to_string(n: Int) -> String

fn not_found() -> Response {
  server.json_response(
    404,
    json.object([#("error", json.string("Not found"))])
    |> json.to_string,
  )
}
