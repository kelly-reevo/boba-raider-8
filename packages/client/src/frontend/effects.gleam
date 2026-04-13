import frontend/model.{type Filter, All, Active, Completed}
import frontend/msg.{type Msg, TodosLoaded, TodosLoadFailed, TodoCreated, TodoCreateFailed}
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/json
import gleam/list
import gleam/option.{Some, None}
import lustre/effect.{type Effect}
import shared.{type Todo, Todo}

/// Fetch todos with optional filter
/// GET /api/todos or GET /api/todos?completed={true|false}
pub fn fetch_todos(filter: Filter) -> Effect(Msg) {
  let url = case filter {
    All -> "/api/todos"
    Active -> "/api/todos?completed=false"
    Completed -> "/api/todos?completed=true"
  }

  let req = request.new()
    |> request.set_method(http.Get)
    |> request.set_host("")
    |> request.set_path(url)

  effect.from(fn(dispatch) {
    case fetch_sync(req) {
      Ok(json_string) -> {
        case decode_todos(json_string) {
          Ok(todos) -> dispatch(TodosLoaded(todos))
          Error(e) -> dispatch(TodosLoadFailed("Failed to parse todos: " <> e))
        }
      }
      Error(e) -> dispatch(TodosLoadFailed(e))
    }
  })
}

/// Create a new todo
/// POST /api/todos
pub fn create_todo(title: String, description: String) -> Effect(Msg) {
  let body = json.object([
    #("title", json.string(title)),
    #("description", json.string(description)),
    #("priority", json.string("medium")),
    #("completed", json.bool(False)),
  ])
  |> json.to_string

  let req = request.new()
    |> request.set_method(http.Post)
    |> request.set_host("")
    |> request.set_path("/api/todos")
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)

  effect.from(fn(dispatch) {
    case fetch_sync(req) {
      Ok(json_string) -> {
        case decode_todo(json_string) {
          Ok(item) -> dispatch(TodoCreated(item))
          Error(_) -> dispatch(TodoCreateFailed("Failed to parse created todo"))
        }
      }
      Error(e) -> dispatch(TodoCreateFailed(e))
    }
  })
}

/// Synchronous fetch for simplicity
fn fetch_sync(req: request.Request(String)) -> Result(String, String) {
  // This uses the browser's fetch API via FFI
  do_fetch_sync(req)
}

@external(javascript, "./effects_ffi.mjs", "fetchSync")
fn do_fetch_sync(req: request.Request(String)) -> Result(String, String)

/// Decode a single todo from JSON
type TodoJson {
  TodoJson(
    id: String,
    title: String,
    description: String,
    priority: String,
    completed: Bool,
    created_at: Int,
    updated_at: Int,
  )
}

fn todo_decoder() -> decode.Decoder(TodoJson) {
  use id <- decode.field("id", decode.string)
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  use priority <- decode.field("priority", decode.string)
  use completed <- decode.field("completed", decode.bool)
  use created_at <- decode.optional_field("created_at", 0, decode.int)
  use updated_at <- decode.optional_field("updated_at", 0, decode.int)

  decode.success(TodoJson(
    id: id,
    title: title,
    description: case description {
      Some(d) -> d
      None -> ""
    },
    priority: priority,
    completed: completed,
    created_at: created_at,
    updated_at: updated_at,
  ))
}

fn decode_todo(json_string: String) -> Result(Todo, String) {
  case json.parse(json_string, todo_decoder()) {
    Ok(t) -> Ok(Todo(
      id: t.id,
      title: t.title,
      description: t.description,
      priority: t.priority,
      completed: t.completed,
      created_at: t.created_at,
      updated_at: t.updated_at,
    ))
    Error(_) -> Error("Failed to decode todo")
  }
}

fn decode_todos(json_string: String) -> Result(List(Todo), String) {
  let decoder = decode.list(todo_decoder())
  case json.parse(json_string, decoder) {
    Ok(items) -> {
      let todos = list.map(items, fn(t) {
        Todo(
          id: t.id,
          title: t.title,
          description: t.description,
          priority: t.priority,
          completed: t.completed,
          created_at: t.created_at,
          updated_at: t.updated_at,
        )
      })
      Ok(todos)
    }
    Error(_) -> Error("Failed to decode todos list")
  }
}

