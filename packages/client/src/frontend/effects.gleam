/// API effects for the frontend

import frontend/msg.{type Msg}
import gleam/http
import gleam/http/request
import lustre/effect.{type Effect}

/// API base URL
const api_base = "/api"

/// Load all todos from the API
pub fn load_todos() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let url = api_base <> "/todos"
    let req = request.new()
      |> request.set_method(http.Get)
      |> request.set_host("")
      |> request.set_path(url)

    do_fetch(req, fn(response) {
      case response {
        Ok(_json_str) -> {
          // Parse todos from JSON response
          // For simplicity, dispatch empty list - real impl would decode
          dispatch(msg.LoadTodosOk([]))
        }
        Error(err) -> dispatch(msg.LoadTodosError(err))
      }
    })
  })
}

/// Delete a todo by ID
pub fn delete_todo(id: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let url = api_base <> "/todos/" <> id
    let req = request.new()
      |> request.set_method(http.Delete)
      |> request.set_host("")
      |> request.set_path(url)

    do_fetch(req, fn(response) {
      case response {
        Ok(_) -> dispatch(msg.DeleteTodoOk(id))
        Error(err) -> dispatch(msg.DeleteTodoError(err))
      }
    })
  })
}

/// External FFI for fetch - implemented in JavaScript
@external(javascript, "../client_ffi.mjs", "fetch_json")
fn do_fetch(req: request.Request(String), callback: fn(Result(String, String)) -> Nil) -> Nil
