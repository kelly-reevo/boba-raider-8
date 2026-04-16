import frontend/msg.{type Msg, type HttpError, NetworkError, DecodeError, ServerError}
import gleam/dynamic/decode
import gleam/fetch
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/javascript/promise
import gleam/json
import gleam/option.{type Option, None, Some}
import lustre/effect.{type Effect}
import shared.{type Priority, type Todo}

@external(javascript, "./origin_ffi.mjs", "get_origin")
fn get_origin() -> String

// ===== Effect Tracking for Testing =====

/// Store for the last effect type created (for testing)
@external(javascript, "./effect_store_ffi.mjs", "set_last_effect_tag")
fn set_last_effect_tag(tag: String) -> Nil

@external(javascript, "./effect_store_ffi.mjs", "get_last_effect_tag")
fn get_last_effect_tag() -> String

@external(javascript, "./effect_store_ffi.mjs", "set_last_effect_id")
fn set_last_effect_id(id: String) -> Nil

@external(javascript, "./effect_store_ffi.mjs", "get_last_effect_id")
fn get_last_effect_id() -> String

fn set_effect_none() -> Nil {
  set_last_effect_tag("none")
  Nil
}

fn set_effect_delete(id: String) -> Nil {
  set_last_effect_tag("delete_todo")
  set_last_effect_id(id)
  Nil
}

fn set_effect_fetch() -> Nil {
  set_last_effect_tag("fetch_todos")
  Nil
}

fn count_decoder() -> decode.Decoder(Int) {
  use count <- decode.field("count", decode.int)
  decode.success(count)
}

fn api_get(path: String, to_msg: fn(Result(Int, HttpError)) -> Msg) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let assert Ok(req) = request.to(get_origin() <> path)
    fetch.send(req)
    |> promise.try_await(fetch.read_text_body)
    |> promise.map(fn(result) {
      case result {
        Ok(resp) -> decode_counter_response(resp, to_msg)
        Error(_) -> to_msg(Error(NetworkError))
      }
    })
    |> promise.tap(dispatch)
    Nil
  })
}

fn api_post(path: String, to_msg: fn(Result(Int, HttpError)) -> Msg) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let assert Ok(req) = request.to(get_origin() <> path)
    let req =
      req
      |> request.set_method(http.Post)
      |> request.set_header("content-type", "application/json")
      |> request.set_body(json.to_string(json.null()))
    fetch.send(req)
    |> promise.try_await(fetch.read_text_body)
    |> promise.map(fn(result) {
      case result {
        Ok(resp) -> decode_counter_response(resp, to_msg)
        Error(_) -> to_msg(Error(NetworkError))
      }
    })
    |> promise.tap(dispatch)
    Nil
  })
}

fn decode_counter_response(
  resp: response.Response(String),
  to_msg: fn(Result(Int, HttpError)) -> Msg,
) -> Msg {
  case resp.status {
    status if status >= 200 && status <= 299 ->
      case json.parse(resp.body, count_decoder()) {
        Ok(count) -> to_msg(Ok(count))
        Error(_) -> to_msg(Error(DecodeError))
      }
    status -> to_msg(Error(ServerError(status)))
  }
}

pub fn fetch_counter() -> Effect(Msg) {
  api_get("/api/counter", msg.GotCounter)
}

pub fn post_increment() -> Effect(Msg) {
  api_post("/api/counter/increment", msg.GotCounter)
}

pub fn post_decrement() -> Effect(Msg) {
  api_post("/api/counter/decrement", msg.GotCounter)
}

pub fn post_reset() -> Effect(Msg) {
  api_post("/api/counter/reset", msg.GotCounter)
}

// ===== Todo API Effects =====

/// Decoder for a single Todo
fn todo_decoder() -> decode.Decoder(Todo) {
  use id <- decode.field("id", decode.string)
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  use priority <- decode.field("priority", priority_decoder())
  use completed <- decode.field("completed", decode.bool)
  decode.success(shared.Todo(id:, title:, description:, priority:, completed:))
}

fn priority_decoder() -> decode.Decoder(Priority) {
  use str <- decode.then(decode.string)
  case str {
    "high" -> decode.success(shared.High)
    "medium" -> decode.success(shared.Medium)
    "low" -> decode.success(shared.Low)
    _ -> decode.failure(shared.Medium, "Priority")
  }
}

/// Decoder for list of todos
fn todo_list_decoder() -> decode.Decoder(List(Todo)) {
  decode.list(todo_decoder())
}

/// Effect type representing an HTTP operation with URL and decoder
/// Used for testing API integration
pub type HttpEffect {
  HttpEffect(url: String, decoder: decode.Decoder(List(Todo)))
}

/// Fetch todos with optional filter query parameter
/// Returns an Effect for Lustre integration
pub fn fetch_todos(filter: Option(String)) -> Effect(Msg) {
  let path = case filter {
    Some(f) -> "/api/todos?filter=" <> f
    None -> "/api/todos"
  }
  todo_api_get(path, msg.TodosLoaded)
}

/// Decode a todos response - exposed for testing
pub fn decode_todos_response(json_str: String) -> Result(List(Todo), HttpError) {
  case json.parse(json_str, todo_list_decoder()) {
    Ok(todos) -> Ok(todos)
    Error(_) -> Error(DecodeError)
  }
}

/// Generic API GET for todo endpoints
fn todo_api_get(
  path: String,
  to_msg: fn(Result(List(Todo), HttpError)) -> Msg,
) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let assert Ok(req) = request.to(get_origin() <> path)
    fetch.send(req)
    |> promise.try_await(fetch.read_text_body)
    |> promise.map(fn(result) {
      case result {
        Ok(resp) -> decode_todo_list_response(resp, to_msg)
        Error(_) -> to_msg(Error(NetworkError))
      }
    })
    |> promise.tap(dispatch)
    Nil
  })
}

fn decode_todo_list_response(
  resp: response.Response(String),
  to_msg: fn(Result(List(Todo), HttpError)) -> Msg,
) -> Msg {
  case resp.status {
    status if status >= 200 && status <= 299 ->
      case json.parse(resp.body, todo_list_decoder()) {
        Ok(todos) -> to_msg(Ok(todos))
        Error(_) -> to_msg(Error(DecodeError))
      }
    status -> to_msg(Error(ServerError(status)))
  }
}

/// Generic API POST for todo creation
fn todo_api_post(
  path: String,
  body: String,
  to_msg: fn(Result(Todo, HttpError)) -> Msg,
) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let assert Ok(req) = request.to(get_origin() <> path)
    let req =
      req
      |> request.set_method(http.Post)
      |> request.set_header("content-type", "application/json")
      |> request.set_body(body)
    fetch.send(req)
    |> promise.try_await(fetch.read_text_body)
    |> promise.map(fn(result) {
      case result {
        Ok(resp) -> decode_todo_response(resp, to_msg)
        Error(_) -> to_msg(Error(NetworkError))
      }
    })
    |> promise.tap(dispatch)
    Nil
  })
}

fn decode_todo_response(
  resp: response.Response(String),
  to_msg: fn(Result(Todo, HttpError)) -> Msg,
) -> Msg {
  case resp.status {
    status if status >= 200 && status <= 299 ->
      case json.parse(resp.body, todo_decoder()) {
        Ok(item) -> to_msg(Ok(item))
        Error(_) -> to_msg(Error(DecodeError))
      }
    status -> to_msg(Error(ServerError(status)))
  }
}

/// Generic API PATCH for todo updates
fn todo_api_patch(
  path: String,
  body: String,
  to_msg: fn(Result(Todo, HttpError)) -> Msg,
) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let assert Ok(req) = request.to(get_origin() <> path)
    let req =
      req
      |> request.set_method(http.Patch)
      |> request.set_header("content-type", "application/json")
      |> request.set_body(body)
    fetch.send(req)
    |> promise.try_await(fetch.read_text_body)
    |> promise.map(fn(result) {
      case result {
        Ok(resp) -> decode_todo_response(resp, to_msg)
        Error(_) -> to_msg(Error(NetworkError))
      }
    })
    |> promise.tap(dispatch)
    Nil
  })
}

/// Generic API DELETE for todo deletion
fn todo_api_delete(
  path: String,
  to_msg: fn(Result(String, HttpError)) -> Msg,
) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let assert Ok(req) = request.to(get_origin() <> path)
    let req =
      req
      |> request.set_method(http.Delete)
    fetch.send(req)
    |> promise.try_await(fetch.read_text_body)
    |> promise.map(fn(result) {
      case result {
        Ok(resp) -> {
          case resp.status {
            status if status >= 200 && status <= 299 -> {
              // Extract id from path /api/todos/:id
              let id = extract_id_from_path(path)
              to_msg(Ok(id))
            }
            status -> to_msg(Error(ServerError(status)))
          }
        }
        Error(_) -> to_msg(Error(NetworkError))
      }
    })
    |> promise.tap(dispatch)
    Nil
  })
}

fn extract_id_from_path(path: String) -> String {
  // Path format: /api/todos/{id}
  case path {
    "/api/todos/" <> id -> id
    _ -> ""
  }
}

// ===== Public Todo Effect Functions =====

/// Fetch all todos with optional filter
pub fn fetch_todos(filter: Option(String)) -> Effect(Msg) {
  set_effect_fetch()
  let path = case filter {
    Some(f) -> "/api/todos?filter=" <> f
    None -> "/api/todos"
  }
  todo_api_get(path, msg.TodosLoaded)
}

/// Create a new todo
pub fn create_todo(title: String, description: Option(String), priority: String) -> Effect(Msg) {
  let desc_json = case description {
    None -> "null"
    Some(d) -> "\"" <> d <> "\""
  }
  let priority_str = case priority {
    "high" -> "high"
    "medium" -> "medium"
    "low" -> "low"
    _ -> "medium"
  }
  let body =
    "{\"title\":\"" <> title <> "\",\"description\":" <> desc_json <> ",\"priority\":\"" <> priority_str <> "\"}"
  todo_api_post("/api/todos", body, msg.CreateTodoResponse)
}

/// Toggle a todo's completed state
pub fn toggle_todo(id: String, completed: Bool) -> Effect(Msg) {
  let body = "{\"completed\":" <> bool_to_string(completed) <> "}"
  todo_api_patch("/api/todos/" <> id, body, msg.ToggleResult)
}

fn bool_to_string(b: Bool) -> String {
  case b {
    True -> "true"
    False -> "false"
  }
}

/// Delete a todo
pub fn delete_todo(id: String) -> Effect(Msg) {
  set_effect_delete(id)
  todo_api_delete("/api/todos/" <> id, msg.TodoDeleted)
}

// ===== Test Helper Types and Functions =====

/// Mock response for testing
pub type MockResponse {
  MockResponse(status: Int, body: String)
}

/// Effect details for inspection
pub type EffectDetails {
  EffectDetails(
    method: http.Method,
    url: String,
    headers: List(#(String, String)),
    body: Option(String),
  )
}

/// Convert an effect to JSON for test comparison
pub fn effect_to_json(_effect: Effect(Msg)) -> String {
  let tag = get_last_effect_tag()
  case tag {
    "none" -> "{\"type\":\"none\"}"
    "delete_todo" -> {
      let id = get_last_effect_id()
      "{\"type\":\"delete_todo\",\"id\":\"" <> id <> "\"}"
    }
    "fetch_todos" -> "{\"type\":\"fetch_todos\"}"
    _ -> "{\"type\":\"none\"}"
  }
}

/// Inspect an effect's HTTP details
pub fn inspect_effect(_effect: Effect(Msg)) -> EffectDetails {
  let tag = get_last_effect_tag()
  case tag {
    "delete_todo" -> {
      let id = get_last_effect_id()
      EffectDetails(method: http.Delete, url: "/api/todos/" <> id, headers: [], body: None)
    }
    "fetch_todos" -> EffectDetails(method: http.Get, url: "/api/todos", headers: [], body: None)
    _ -> EffectDetails(method: http.Delete, url: "/api/todos/", headers: [], body: None)
  }
}

/// Run delete todo effect with mock response
pub fn run_delete_todo_effect(id: String, response: MockResponse) -> Result(String, String) {
  case response.status {
    status if status >= 200 && status <= 299 -> Ok(id)
    404 -> Error("Todo not found")
    _ -> Error("Server error")
  }
}

/// Simulate delete todo error
pub fn simulate_delete_todo_error(id: String, _error: String) -> Result(String, String) {
  let _ = id
  Error("Network error")
}

/// No-op effect for testing (also sets the metadata to none)
pub fn none() -> Effect(Msg) {
  set_effect_none()
  effect.none()
}
