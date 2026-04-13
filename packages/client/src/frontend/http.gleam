/// HTTP client using FFI

import frontend/msg.{type Msg}
import frontend/model as model
import lustre/effect.{type Effect}

/// HTTP methods
pub type Method {
  Get
  Post
  Put
  Patch
  Delete
}

/// Make an HTTP request
pub fn request(
  method: Method,
  url: String,
  headers: List(#(String, String)),
  body: String,
  expect: Expect,
) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    do_request(method_to_string(method), url, headers, body, expect, dispatch)
    Nil
  })
}

/// Method to string
fn method_to_string(method: Method) -> String {
  case method {
    Get -> "GET"
    Post -> "POST"
    Put -> "PUT"
    Patch -> "PATCH"
    Delete -> "DELETE"
  }
}

/// Expect type for response handling
pub type Expect {
  ExpectJsonTodoList(fn(List(model.Todo)) -> Msg, fn(String) -> Msg)
  ExpectJsonTodo(fn(model.Todo) -> Msg, fn(String) -> Msg)
  ExpectAnything(fn() -> Msg, fn(String) -> Msg)
}

@external(javascript, "./http_ffi.mjs", "doRequest")
pub fn do_request(
  method: String,
  url: String,
  headers: List(#(String, String)),
  body: String,
  expect: Expect,
  dispatch: fn(Msg) -> Nil,
) -> Nil
