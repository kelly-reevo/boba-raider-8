import frontend/msg.{type Msg, TodoToggledError, TodoToggledOk, TodosLoaded, SetError}
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/json
import gleam/option.{None, Some}
import lustre/effect.{type Effect}
import shared.{type Todo, Todo}

/// Effect to fetch all todos from GET /api/todos
pub fn fetch_todos() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    case request.to("http://localhost:3000/api/todos") {
      Error(_) -> dispatch(SetError("Failed to load todos"))
      Ok(req) -> {
        do_fetch(req, fn(response) {
          case response {
            Ok(json_string) -> {
              case decode_todo_list(json_string) {
                Ok(todos) -> dispatch(TodosLoaded(todos))
                Error(_) -> dispatch(SetError("Failed to load todos"))
              }
            }
            Error(_) -> dispatch(SetError("Failed to load todos"))
          }
        })
      }
    }
  })
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

/// Effect to PATCH /api/todos/:id to update completion status
pub fn patch_todo(id: String, completed: Bool) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // Build request
    let body = json.object([#("completed", json.bool(completed))])
      |> json.to_string()

    let req_result = request.to("http://localhost:3000/api/todos/" <> id)

    // Send request using browser fetch API via FFI
    case req_result {
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

@external(javascript, "./effects_ffi.mjs", "do_fetch")
fn do_fetch(req: request.Request(String), callback: fn(Result(String, Nil)) -> Nil) -> Nil {
  Nil
}

/// Decode a Todo from JSON string
fn decode_todo(json_string: String) -> Result(Todo, Nil) {
  let decoder = {
    use id <- decode.field("id", decode.string)
    use title <- decode.field("title", decode.string)
    use completed <- decode.field("completed", decode.bool)
    use priority <- decode.optional_field("priority", "medium", decode.string)
    use description <- decode.optional_field("description", None, decode.optional(decode.string))
    use created_at <- decode.optional_field("created_at", 0, decode.int)
    decode.success(Todo(id, title, description, priority, completed, created_at, created_at))
  }

  case json.parse(json_string, decoder) {
    Ok(todo_item) -> Ok(todo_item)
    Error(_) -> Error(Nil)
  }
}
