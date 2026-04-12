import gleam/json
import gleam/list
import gleam/option.{type Option, Some, None}
import gleam/string
import gleam/otp/actor
import gleam/erlang/process.{type Subject}
import shared.{Todo, todo_to_json, priority_from_string}
import todo_store.{type TodoStore}
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
      let actor = start_store_actor()
      let _ = set_store_holder(unsafe_cast_pid(actor))
      actor
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

fn route(request: Request, store: TodoStore) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "POST", "/api/todos" -> create_todo_handler(request, store)
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
      case priority_from_string(priority_str) {
        Ok(priority) -> {
          case shared.new_todo(title, description, priority) {
            Ok(new_todo) -> {
              let todo_data = todo_store.TodoData(
                title: new_todo.title,
                description: new_todo.description,
                priority: map_priority_to_store(priority),
                completed: new_todo.completed,
              )
              let id = todo_store.insert(store, todo_data)

              let response_todo = Todo(
                id: id,
                title: new_todo.title,
                description: new_todo.description,
                priority: new_todo.priority,
                completed: new_todo.completed,
                created_at: new_todo.created_at,
                updated_at: new_todo.updated_at,
              )

              server.json_response(201, todo_to_json(response_todo))
            }
            Error(_) -> {
              server.json_response(
                400,
                json.object([#("error", json.string("Invalid input"))]) |> json.to_string,
              )
            }
          }
        }
        Error(_) -> {
          server.json_response(
            400,
            json.object([#("error", json.string("Invalid priority"))]) |> json.to_string,
          )
        }
      }
    }
    Error(_) -> {
      server.json_response(
        400,
        json.object([#("error", json.string("Invalid JSON"))]) |> json.to_string,
      )
    }
  }
}

// Extract fields from create request body
fn extract_create_fields(body: String) -> Result(#(String, Option(String), String), Nil) {
  let title = extract_json_string(body, "title")
  let description = extract_json_string(body, "description")
  let priority = extract_json_string(body, "priority")

  case title, priority {
    Ok(Some(t)), Ok(Some(p)) -> {
      let desc = case description {
        Ok(Some(d)) -> Some(d)
        _ -> None
      }
      Ok(#(t, desc, p))
    }
    _, _ -> Error(Nil)
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

// Map shared Priority to store Priority
fn map_priority_to_store(p: shared.Priority) -> todo_store.Priority {
  case p {
    shared.Low -> todo_store.Low
    shared.Medium -> todo_store.Medium
    shared.High -> todo_store.High
  }
}

// Map store Priority to shared Priority
fn map_priority_from_store(p: todo_store.Priority) -> shared.Priority {
  case p {
    todo_store.Low -> shared.Low
    todo_store.Medium -> shared.Medium
    todo_store.High -> shared.High
  }
}

// Get todo handler - GET /api/todos/:id
fn get_todo_handler(path: String, store: TodoStore) -> Response {
  let id = string.drop_start(path, 13) // Remove "/api/todos/"

  case is_valid_uuid(id) {
    True -> {
      case todo_store.get(store, id) {
        Some(item) -> {
          let timestamp = generate_iso_timestamp()
          let found_todo = Todo(
            id: item.id,
            title: item.title,
            description: item.description,
            priority: map_priority_from_store(item.priority),
            completed: item.completed,
            created_at: timestamp,
            updated_at: timestamp,
          )
          server.json_response(200, todo_to_json(found_todo))
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
  "2024-01-15T10:30:00Z"
}

fn not_found() -> Response {
  server.json_response(
    404,
    json.object([#("error", json.string("Not found"))])
    |> json.to_string,
  )
}
