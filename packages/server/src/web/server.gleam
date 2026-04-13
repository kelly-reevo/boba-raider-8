import gleam/dict.{type Dict}

// Re-export types as both types and value constructors for compatibility
pub type Request {
  Request(method: String, path: String, headers: Dict(String, String), body: String)
}

pub type Response {
  Response(status: Int, headers: Dict(String, String), body: String)
}

// Constructor functions for tests
pub fn request(
  method method: String,
  path path: String,
  headers headers: Dict(String, String),
  body body: String,
) -> Request {
  Request(method:, path:, headers:, body:)
}

pub fn response(
  status status: Int,
  headers headers: Dict(String, String),
  body body: String,
) -> Response {
  Response(status:, headers:, body:)
}

pub fn json_response(status: Int, body: String) -> Response {
  Response(
    status: status,
    headers: dict.from_list([#("Content-Type", "application/json")]),
    body: body,
  )
}

pub fn html_response(status: Int, body: String) -> Response {
  Response(
    status: status,
    headers: dict.from_list([#("Content-Type", "text/html; charset=utf-8")]),
    body: body,
  )
}

pub fn text_response(status: Int, body: String) -> Response {
  Response(
    status: status,
    headers: dict.from_list([#("Content-Type", "text/plain")]),
    body: body,
  )
}
