/// API effects for todo operations with loading states

import frontend/msg.{type Msg, CreateLoading, DeleteLoading, ListLoading, TodosLoaded, TodoCreated, TodoUpdated, TodoDeleted, LoadTodosFailed, CreateTodoFailed, UpdateTodoFailed, DeleteTodoFailed, StartLoading, StopLoading, UpdateLoading}
import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None, Some}
import lustre/effect.{type Effect}
import shared.{type Priority, type Todo, High, Low, Medium, Todo}

// ============================================================
// API Configuration
// ============================================================

const api_base = "/api"

// ============================================================
// JSON Decoders
// ============================================================

fn priority_decoder() -> decode.Decoder(Priority) {
  decode.string
  |> decode.then(fn(str) {
    case str {
      "low" -> decode.success(Low)
      "medium" -> decode.success(Medium)
      "high" -> decode.success(High)
      _ -> decode.success(Medium)
    }
  })
}

fn todo_decoder() -> decode.Decoder(Todo) {
  decode.field("id", decode.string, fn(id) {
    decode.field("title", decode.string, fn(title) {
      decode.field("description", decode.optional(decode.string), fn(description) {
        decode.field("priority", priority_decoder(), fn(priority) {
          decode.field("completed", decode.bool, fn(completed) {
            decode.field("created_at", decode.string, fn(created_at) {
              decode.field("updated_at", decode.string, fn(updated_at) {
                decode.success(Todo(
                  id: id,
                  title: title,
                  description: description,
                  priority: priority,
                  completed: completed,
                  created_at: created_at,
                  updated_at: updated_at,
                ))
              })
            })
          })
        })
      })
    })
  })
}

fn todos_decoder() -> decode.Decoder(List(Todo)) {
  decode.list(todo_decoder())
}

fn error_decoder() -> decode.Decoder(String) {
  decode.field("error", decode.string, fn(error) {
    decode.success(error)
  })
}

// ============================================================
// FFI - HTTP Request
// ============================================================

/// Fetch result type returned by FFI
pub type FetchResult {
  FetchSuccess(status: Int, body: String)
  FetchError(String)
}

/// Make a fetch request via FFI - returns Nil immediately, dispatches via callback
@external(javascript, "./fetch_ffi.mjs", "fetchWithCallback")
fn fetch_with_callback(
  url: String,
  method: String,
  body: Option(String),
  callback: fn(FetchResult) -> Nil,
) -> Nil

// ============================================================
// API Operations with Loading States
// ============================================================

/// Load all todos with loading state management
pub fn load_todos() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // Start loading
    dispatch(StartLoading(ListLoading))

    // Make the request with callback
    let url = api_base <> "/todos"
    fetch_with_callback(url, "GET", None, fn(result) {
      case result {
        FetchSuccess(status, body) if status >= 200 && status < 300 -> {
          case json.parse(from: body, using: todos_decoder()) {
            Ok(todos) -> {
              dispatch(TodosLoaded(todos))
              dispatch(StopLoading(ListLoading))
            }
            Error(_) -> {
              dispatch(LoadTodosFailed("Failed to parse todos"))
              dispatch(StopLoading(ListLoading))
            }
          }
        }
        FetchSuccess(_, body) -> {
          case json.parse(from: body, using: error_decoder()) {
            Ok(error_msg) -> {
              dispatch(LoadTodosFailed(error_msg))
            }
            Error(_) -> {
              dispatch(LoadTodosFailed("Failed to load todos"))
            }
          }
          dispatch(StopLoading(ListLoading))
        }
        FetchError(err) -> {
          dispatch(LoadTodosFailed(err))
          dispatch(StopLoading(ListLoading))
        }
      }
    })
  })
}

/// Create a new todo with loading state management
pub fn create_todo(title: String, description: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // Start loading
    dispatch(StartLoading(CreateLoading))

    // Build request body
    let desc_json = case description {
      "" -> json.null()
      d -> json.string(d)
    }
    let body = json.object([
      #("title", json.string(title)),
      #("description", desc_json),
      #("priority", json.string("medium")),
    ])
    |> json.to_string()

    // Make the request
    let url = api_base <> "/todos"
    fetch_with_callback(url, "POST", Some(body), fn(result) {
      case result {
        FetchSuccess(status, body) if status >= 200 && status < 300 -> {
          case json.parse(from: body, using: todo_decoder()) {
            Ok(new_todo) -> {
              dispatch(TodoCreated(new_todo))
              dispatch(StopLoading(CreateLoading))
            }
            Error(_) -> {
              dispatch(CreateTodoFailed("Failed to parse created todo"))
              dispatch(StopLoading(CreateLoading))
            }
          }
        }
        FetchSuccess(_, body) -> {
          case json.parse(from: body, using: error_decoder()) {
            Ok(error_msg) -> {
              dispatch(CreateTodoFailed(error_msg))
            }
            Error(_) -> {
              dispatch(CreateTodoFailed("Failed to create todo"))
            }
          }
          dispatch(StopLoading(CreateLoading))
        }
        FetchError(err) -> {
          dispatch(CreateTodoFailed(err))
          dispatch(StopLoading(CreateLoading))
        }
      }
    })
  })
}

/// Update a todo (toggle completion) with loading state management
pub fn update_todo(todo_id: String, completed: Bool) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // Start loading for this specific todo
    dispatch(StartLoading(UpdateLoading(todo_id)))

    // Build request body
    let body = json.object([
      #("completed", json.bool(completed)),
    ])
    |> json.to_string()

    // Make the request
    let url = api_base <> "/todos/" <> todo_id
    fetch_with_callback(url, "PATCH", Some(body), fn(result) {
      case result {
        FetchSuccess(status, body) if status >= 200 && status < 300 -> {
          case json.parse(from: body, using: todo_decoder()) {
            Ok(updated_todo) -> {
              dispatch(TodoUpdated(updated_todo))
              dispatch(StopLoading(UpdateLoading(todo_id)))
            }
            Error(_) -> {
              dispatch(UpdateTodoFailed(todo_id, completed, "Failed to parse updated todo"))
              dispatch(StopLoading(UpdateLoading(todo_id)))
            }
          }
        }
        FetchSuccess(_, body) -> {
          case json.parse(from: body, using: error_decoder()) {
            Ok(error_msg) -> {
              dispatch(UpdateTodoFailed(todo_id, completed, error_msg))
            }
            Error(_) -> {
              dispatch(UpdateTodoFailed(todo_id, completed, "Failed to update todo"))
            }
          }
          dispatch(StopLoading(UpdateLoading(todo_id)))
        }
        FetchError(err) -> {
          dispatch(UpdateTodoFailed(todo_id, completed, err))
          dispatch(StopLoading(UpdateLoading(todo_id)))
        }
      }
    })
  })
}

/// Delete a todo with loading state management
pub fn delete_todo(todo_id: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // Start loading for this specific todo
    dispatch(StartLoading(DeleteLoading(todo_id)))

    // Make the request
    let url = api_base <> "/todos/" <> todo_id
    fetch_with_callback(url, "DELETE", None, fn(result) {
      case result {
        FetchSuccess(status, _) if status >= 200 && status < 300 -> {
          dispatch(TodoDeleted(todo_id))
          dispatch(StopLoading(DeleteLoading(todo_id)))
        }
        FetchSuccess(_, body) -> {
          case json.parse(from: body, using: error_decoder()) {
            Ok(error_msg) -> {
              dispatch(DeleteTodoFailed(todo_id, error_msg))
            }
            Error(_) -> {
              dispatch(DeleteTodoFailed(todo_id, "Failed to delete todo"))
            }
          }
          dispatch(StopLoading(DeleteLoading(todo_id)))
        }
        FetchError(err) -> {
          dispatch(DeleteTodoFailed(todo_id, err))
          dispatch(StopLoading(DeleteLoading(todo_id)))
        }
      }
    })
  })
}
