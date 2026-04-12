import gleeunit
import gleeunit/should
import gleam/dict
import gleam/string
import config
import web/router
import web/server

pub fn main() {
  gleeunit.main()
}

pub fn config_load_test() {
  let cfg = config.load()
  cfg.port
  |> should.equal(3000)
}

// ============================================================================
// API Error Response Tests
// ============================================================================

/// Invalid JSON in request body returns 400 with 'Invalid JSON' error
pub fn invalid_json_returns_400_test() {
  let request = server.Request(
    method: "POST",
    path: "/api/todos",
    headers: dict.from_list([#("content-type", "application/json")]),
    body: "{invalid json",
  )

  let response = router.handle_request(request)

  response.status
  |> should.equal(400)

  let content_type = dict.get(response.headers, "Content-Type")
  content_type
  |> should.equal(Ok("application/json"))

  response.body
  |> string.contains("Invalid JSON")
  |> should.equal(True)
}

/// Server error returns 500 with generic error message (no stack trace leaked)
pub fn server_error_returns_500_test() {
  let request = server.Request(
    method: "GET",
    path: "/api/todos/trigger-error",
    headers: dict.new(),
    body: "",
  )

  let response = router.handle_request(request)

  response.status
  |> should.equal(500)

  let content_type = dict.get(response.headers, "Content-Type")
  content_type
  |> should.equal(Ok("application/json"))

  response.body
  |> string.contains("error")
  |> should.equal(True)

  response.body
  |> string.contains("at line")
  |> should.equal(False)

  response.body
  |> string.contains("Stack trace")
  |> should.equal(False)

  response.body
  |> string.contains(".gleam:")
  |> should.equal(False)
}

/// Error response format follows {error: string}
pub fn error_response_format_test() {
  let request = server.Request(
    method: "POST",
    path: "/api/todos",
    headers: dict.from_list([#("content-type", "application/json")]),
    body: "{}",
  )

  let response = router.handle_request(request)

  let content_type = dict.get(response.headers, "Content-Type")
  content_type
  |> should.equal(Ok("application/json"))

  // Response should be valid JSON with error field
  response.body
  |> string.contains("\"error\"")
  |> should.equal(True)
}

/// 404 error returns consistent format
pub fn not_found_error_format_test() {
  let request = server.Request(
    method: "GET",
    path: "/api/todos/non-existent-id-12345",
    headers: dict.new(),
    body: "",
  )

  let response = router.handle_request(request)

  response.status
  |> should.equal(404)

  let content_type = dict.get(response.headers, "Content-Type")
  content_type
  |> should.equal(Ok("application/json"))

  response.body
  |> string.contains("error")
  |> should.equal(True)
}
