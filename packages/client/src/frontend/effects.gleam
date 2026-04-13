/// HTTP effects for todo operations

import frontend/model.{type Filter, All, Active, Completed}
import frontend/msg.{type Msg, TodosLoaded, TodosLoadError, CreateTodoSucceeded, CreateTodoFailed, Deleted, DeleteError, TodoToggledOk, TodoToggledError, SetError, TodosFetched, FetchError}
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/json
import gleam/option.{None, Some}
import lustre/effect.{type Effect}
import shared.{type Todo, type Priority, Todo, High, Low, Medium}

/// Priority to string
fn priority_to_string(priority: Priority) -> String {
  case priority {
    Low -> "low"
    Medium -> "medium"
    High -> "high"
  }
}

/// Effect to fetch todos with optional filter
pub fn get_todos(filter: Filter) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    case request.to("http://localhost:3000/api/todos" <> filter_to_query(filter)) {
      Error(_) -> dispatch(FetchError("Failed to load todos"))
      Ok(req) -> {
        do_fetch(req, fn(response) {
          case response {
            Ok(json_string) -> {
              case decode_todo_list(json_string) {
                Ok(todos) -> dispatch(TodosFetched(todos))
                Error(_) -> dispatch(FetchError("Failed to parse todos"))
              }
            }
            Error(_) -> dispatch(FetchError("Failed to load todos"))
          }
        })
      }
    }
  })
}

/// Convert filter to query string
fn filter_to_query(filter: Filter) -> String {
  case filter {
    All -> ""
    Active -> "?filter=active"
    Completed -> "?filter=completed"
  }
}

/// Decode a list of Todos from JSON string
fn decode_todo_list(json_string: String) -> Result(List(Todo), Nil) {
  let todo_decoder = {
    use id <- decode.field("id", decode.string)
    use title <- decode.field("title", decode.string)
    use completed <- decode.field("completed", decode.bool)
    use priority <- decode.optional_field("priority", "medium", decode.string)
    use description <- decode.optional_field("description", None, decode.optional(decode.string))
    use created_at <- decode.optional_field("created_at", 0, decode.int)
    decode.success(Todo(id, title, description, priority, completed, created_at, created_at))
  }

  let decoder = decode.list(of: todo_decoder)

  case json.parse(json_string, decoder) {
    Ok(todos) -> Ok(todos)
    Error(_) -> Error(Nil)
  }
}

/// Decode a Todo from JSON string
fn decode_todo(json_string: String) -> Result(Todo, Nil) {
  let todo_decoder = {
    use id <- decode.field("id", decode.string)
    use title <- decode.field("title", decode.string)
    use completed <- decode.field("completed", decode.bool)
    use priority <- decode.optional_field("priority", "medium", decode.string)
    use description <- decode.optional_field("description", None, decode.optional(decode.string))
    use created_at <- decode.optional_field("created_at", 0, decode.int)
    decode.success(Todo(id, title, description, priority, completed, created_at, created_at))
  }

  case json.parse(json_string, todo_decoder) {
    Ok(todo_item) -> Ok(todo_item)
    Error(_) -> Error(Nil)
  }
}

/// Fetch todos from the API
pub fn fetch_todos() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    case request.to("http://localhost:3000/api/todos") {
      Error(_) -> dispatch(TodosLoadError("Failed to load todos"))
      Ok(req) -> {
        do_fetch(req, fn(response) {
          case response {
            Ok(json_string) -> {
              case decode_todo_list(json_string) {
                Ok(todos) -> dispatch(TodosLoaded(todos))
                Error(_) -> dispatch(TodosLoadError("Failed to parse todos"))
              }
            }
            Error(_) -> dispatch(TodosLoadError("Failed to load todos"))
          }
        })
      }
    }
  })
}

/// Create a new todo via API
pub fn create_todo(
  title: String,
  description: String,
  priority: Priority,
) -> Effect(Msg) {
  let priority_str = priority_to_string(priority)

  let body_obj =
    json.object([
      #("title", json.string(title)),
      #("description", json.string(description)),
      #("priority", json.string(priority_str)),
      #("completed", json.bool(False)),
    ])
  let body = json.to_string(body_obj)

  effect.from(fn(dispatch) {
    case request.to("http://localhost:3000/api/todos") {
      Error(_) -> dispatch(CreateTodoFailed("Failed to create todo"))
      Ok(req) -> {
        let req_with_method = request.set_method(req, http.Post)
        let req_with_header = request.set_header(req_with_method, "Content-Type", "application/json")
        let final_req = request.set_body(req_with_header, body)

        do_fetch(final_req, fn(response) {
          case response {
            Ok(json_string) -> {
              case decode_todo(json_string) {
                Ok(todo_item) -> dispatch(CreateTodoSucceeded(todo_item))
                Error(_) -> dispatch(CreateTodoFailed("Failed to parse created todo"))
              }
            }
            Error(_) -> dispatch(CreateTodoFailed("Failed to create todo"))
          }
        })
      }
    }
  })
}

/// Effect that chains create and then refresh
pub fn create_todo_and_refresh(
  title: String,
  description: String,
  priority: Priority,
) -> Effect(Msg) {
  create_todo(title, description, priority)
}

/// Delete a todo by ID
pub fn delete_todo(id: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    case request.to("http://localhost:3000/api/todos/" <> id) {
      Error(_) -> dispatch(DeleteError("Failed to delete todo"))
      Ok(req) -> {
        let req_with_method = request.set_method(req, http.Delete)
        do_fetch(req_with_method, fn(response) {
          case response {
            Ok(_) -> dispatch(Deleted(id))
            Error(_) -> dispatch(DeleteError("Failed to delete todo"))
          }
        })
      }
    }
  })
}

/// Effect to PATCH /api/todos/:id to update completion status
pub fn patch_todo(id: String, completed: Bool) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let body = json.object([#("completed", json.bool(completed))])
      |> json.to_string()

    case request.to("http://localhost:3000/api/todos/" <> id) {
      Error(_) -> {
        dispatch(TodoToggledError(id, !completed))
        dispatch(SetError("Failed to update todo"))
      }
      Ok(req) -> {
        let req_with_method = request.set_method(req, http.Patch)
        let req_with_header = request.set_header(req_with_method, "Content-Type", "application/json")
        let final_req = request.set_body(req_with_header, body)

        do_fetch(final_req, fn(response) {
          case response {
            Ok(json_string) -> {
              case decode_todo(json_string) {
                Ok(todo_item) -> dispatch(TodoToggledOk(todo_item))
                Error(_) -> {
                  dispatch(TodoToggledError(id, !completed))
                  dispatch(SetError("Failed to update todo"))
                }
              }
            }
            Error(_) -> {
              dispatch(TodoToggledError(id, !completed))
              dispatch(SetError("Failed to update todo"))
            }
          }
        })
      }
    }
  })
}

/// FFI: Perform HTTP fetch
@external(javascript, "./effects_ffi.mjs", "do_fetch")
fn do_fetch(req: request.Request(String), callback: fn(Result(String, Nil)) -> Nil) -> Nil
