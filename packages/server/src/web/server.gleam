import gleam/dict.{type Dict}

// Internal type with positional constructor
pub type HttpRequest {
  HttpRequest(method: String, path: String, headers: Dict(String, String), body: String)
}

// Type alias for external use
pub type Request =
  HttpRequest

// Constructor function with named arguments for test compatibility
pub fn request(
  method method: String,
  path path: String,
  headers headers: Dict(String, String),
  body body: String,
) -> Request {
  HttpRequest(method, path, headers, body)
}

// Internal type with positional constructor
pub type HttpResponse {
  HttpResponse(status: Int, headers: Dict(String, String), body: String)
}

// Type alias for external use
pub type Response =
  HttpResponse

// Constructor function with named arguments for test compatibility
pub fn response(
  status status: Int,
  headers headers: Dict(String, String),
  body body: String,
) -> Response {
  HttpResponse(status, headers, body)
}

pub fn json_response(status: Int, body: String) -> Response {
  response(
    status: status,
    headers: dict.from_list([#("Content-Type", "application/json")]),
    body: body,
  )
}

pub fn html_response(status: Int, body: String) -> Response {
  response(
    status: status,
    headers: dict.from_list([#("Content-Type", "text/html; charset=utf-8")]),
    body: body,
  )
}

pub fn text_response(status: Int, body: String) -> Response {
  response(
    status: status,
    headers: dict.from_list([#("Content-Type", "text/plain")]),
    body: body,
  )
}
