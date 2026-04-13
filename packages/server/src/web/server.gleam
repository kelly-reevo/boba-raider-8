import gleam/dict.{type Dict}

// Re-export types as both types and value constructors for compatibility
/// Request type for HTTP requests
pub type Request {
  Request(
    method: String,
    path: String,
    query_string: String,
    headers: Dict(String, String),
    body: String,
  )
}

/// Response type for HTTP responses
pub type Response {
  Response(status: Int, headers: Dict(String, String), body: String)
}

// Type aliases for backward compatibility
pub type HttpRequest =
  Request

pub type HttpResponse =
  Response

// Constructor functions for tests
/// Constructor function with named arguments for test compatibility
pub fn request(
  method method: String,
  path path: String,
  headers headers: Dict(String, String),
  body body: String,
) -> Request {
  Request(method:, path:, headers:, body:)
}

/// Constructor function for responses
pub fn response(
  status status: Int,
  headers headers: Dict(String, String),
  body body: String,
) -> Response {
  Response(status:, headers:, body:)
}

/// Empty headers helper
pub fn empty_headers() -> Dict(String, String) {
  dict.new()
}

/// Create a JSON response with the given status
pub fn json_response(status: Int, body: String) -> Response {
  response(
    status: status,
    headers: dict.from_list([#("Content-Type", "application/json")]),
    body: body,
  )
}

/// Create an HTML response with the given status
pub fn html_response(status: Int, body: String) -> Response {
  response(
    status: status,
    headers: dict.from_list([#("Content-Type", "text/html; charset=utf-8")]),
    body: body,
  )
}

/// Create a text response with the given status
pub fn text_response(status: Int, body: String) -> Response {
  response(
    status: status,
    headers: dict.from_list([#("Content-Type", "text/plain")]),
    body: body,
  )
}
