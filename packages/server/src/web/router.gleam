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
import web/todos

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
    "POST", "/api/todos" -> todos.create_todo(store, request)
    "PATCH", path -> {
      case string.starts_with(path, "/api/todos/") {
        True -> todos.patch_todo(store, request)
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

fn not_found() -> Response {
  server.json_response(
    404,
    json.object([#("error", json.string("Not found"))])
    |> json.to_string,
  )
}
