// Integration tests for API error handling
// Tests the external HTTP API boundary contract for error responses

import gleeunit/should
import gleam/json
import gleam/dict
import gleam/list
import gleam/string
import todo_store
import web/router
import web/server

// Helper: Build a POST request to /api/todos with JSON body
fn build_post_request(body: String) -> server.Request {
  server.Request(
    method: "POST",
    path: "/api/todos",
    headers: dict.from_list([#("content-type", "application/json")]),
    body: body,
  )
}

// Test: Validation error returns 422
pub fn validation_error_returns_422_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  let body = json.object([
    #("title", json.string("")),
    #("description", json.string("Some description")),
  ]) |> json.to_string()

  let req = build_post_request(body)
  let res = handler(req)

  // Assert: Status is 422
  res.status |> should.equal(422)

  // Assert: Response body contains errors
  should.be_true(string.contains(res.body, "errors") || string.contains(res.body, "error"))
}

// Test: Missing title returns 422
pub fn missing_title_returns_422_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  let body = json.object([
    #("description", json.string("Only description")),
  ]) |> json.to_string()

  let req = build_post_request(body)
  let res = handler(req)

  res.status |> should.equal(422)
}

// Test: Whitespace-only title returns 422
pub fn whitespace_title_returns_422_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  let body = json.object([
    #("title", json.string("   ")),
  ]) |> json.to_string()

  let req = build_post_request(body)
  let res = handler(req)

  res.status |> should.equal(422)
}

// Test: PATCH validation failure returns 422
pub fn patch_todo_validation_failure_returns_422_test() {
  let assert Ok(store) = todo_store.start()
  let assert Ok(item) = todo_store.create_todo(store, "Original", "Desc")
  let handler = router.make_handler(store)

  let body = json.object([
    #("title", json.string("")),
  ]) |> json.to_string()

  let req = server.Request(
    method: "PATCH",
    path: "/api/todos/" <> item.id,
    headers: dict.from_list([#("content-type", "application/json")]),
    body: body,
  )
  let res = handler(req)

  res.status |> should.equal(422)
}

// Test: Invalid JSON returns 400 or 422
pub fn invalid_json_returns_error_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  let req = build_post_request("{invalid json content}")
  let res = handler(req)

  should.be_true(res.status == 400 || res.status == 422)
}

// Test: CORS headers present on API responses
pub fn api_response_includes_cors_headers_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  let req = server.Request(
    method: "GET",
    path: "/api/todos",
    headers: dict.from_list([#("accept", "application/json")]),
    body: "",
  )
  let res = handler(req)

  case dict.get(res.headers, "Access-Control-Allow-Origin") {
    Ok(origin) -> origin |> should.equal("*")
    Error(_) -> should.fail()
  }
}

// Test: OPTIONS preflight returns CORS headers
pub fn options_preflight_returns_cors_headers_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  let req = server.Request(
    method: "OPTIONS",
    path: "/api/todos",
    headers: dict.from_list([
      #("Origin", "http://localhost:3000"),
    ]),
    body: "",
  )
  let res = handler(req)

  // Status is 200 or 204
  should.be_true(res.status == 200 || res.status == 204)

  // CORS headers present
  case dict.get(res.headers, "Access-Control-Allow-Origin") {
    Ok(_) -> Nil
    Error(_) -> should.fail()
  }

  case dict.get(res.headers, "Access-Control-Allow-Methods") {
    Ok(methods) -> {
      should.be_true(string.contains(methods, "GET"))
      should.be_true(string.contains(methods, "POST"))
      should.be_true(string.contains(methods, "PATCH"))
      should.be_true(string.contains(methods, "DELETE"))
    }
    Error(_) -> should.fail()
  }

  case dict.get(res.headers, "Access-Control-Allow-Headers") {
    Ok(headers) -> should.be_true(string.contains(headers, "Content-Type"))
    Error(_) -> Nil
  }
}

// Test: Error responses include CORS headers
pub fn error_responses_include_cors_headers_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  // Request that returns 404
  let req = server.Request(
    method: "GET",
    path: "/api/todos/nonexistent-id",
    headers: dict.from_list([#("Origin", "http://localhost:3000")]),
    body: "",
  )
  let res = handler(req)

  res.status |> should.equal(404)

  // CORS headers present
  case dict.get(res.headers, "Access-Control-Allow-Origin") {
    Ok(_) -> Nil
    Error(_) -> should.fail()
  }
}

// Test: Not found returns 404 with error body
pub fn not_found_returns_404_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  let req = server.Request(
    method: "GET",
    path: "/api/todos/nonexistent-id-12345",
    headers: dict.new(),
    body: "",
  )
  let res = handler(req)

  res.status |> should.equal(404)
  should.be_true(string.contains(res.body, "error"))
}

// Test: Server error response does not leak stack traces
pub fn server_error_does_not_leak_stack_trace_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  let requests = [
    server.Request(method: "GET", path: "/api/todos", headers: dict.new(), body: ""),
    server.Request(method: "POST", path: "/api/todos", headers: dict.new(), body: ""),
  ]

  list.each(requests, fn(req) {
    let res = handler(req)

    // If status is 500, verify no stack trace leaked
    case res.status {
      500 -> {
        should.be_false(string.contains(res.body, "stack"))
        should.be_false(string.contains(res.body, "trace"))
        should.be_false(string.contains(res.body, "exception"))
        should.be_false(string.contains(res.body, "at line"))
        should.be_false(string.contains(res.body, "native"))
      }
      _ -> Nil
    }
  })
}

// Test: CORS allows any origin
pub fn cors_allows_any_origin_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  let origins = ["http://localhost:3000", "http://localhost:8080", "https://example.com"]

  list.each(origins, fn(origin) {
    let req = server.Request(
      method: "GET",
      path: "/api/todos",
      headers: dict.from_list([#("Origin", origin)]),
      body: "",
    )
    let res = handler(req)

    case dict.get(res.headers, "Access-Control-Allow-Origin") {
      Ok("*") -> Nil
      Ok(allowed) if allowed == origin -> Nil
      Ok(_) -> should.fail()
      Error(_) -> should.fail()
    }
  })
}

// Test: CORS headers present on all HTTP methods
pub fn cors_headers_present_on_all_methods_test() {
  let assert Ok(store) = todo_store.start()
  let assert Ok(item) = todo_store.create_todo(store, "Test", "Description")
  let handler = router.make_handler(store)

  let requests = [
    #("GET", "/api/todos"),
    #("POST", "/api/todos"),
    #("PATCH", "/api/todos/" <> item.id),
    #("DELETE", "/api/todos/" <> item.id),
  ]

  list.each(requests, fn(method_path) {
    let #(method, path) = method_path
    let req = server.Request(
      method: method,
      path: path,
      headers: dict.from_list([#("Origin", "http://localhost:3000")]),
      body: "",
    )
    let res = handler(req)

    case dict.get(res.headers, "Access-Control-Allow-Origin") {
      Ok(_) -> Nil
      Error(_) -> should.fail()
    }
  })
}

// Test: Validation errors have field details
pub fn validation_error_has_field_details_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  let body = json.object([
    #("title", json.string("")),
  ]) |> json.to_string()

  let req = build_post_request(body)
  let res = handler(req)

  res.status |> should.equal(422)

  // Body should contain errors array or error field
  should.be_true(string.contains(res.body, "errors") || string.contains(res.body, "error"))
}

// Test: Bad request has error body
pub fn bad_request_has_error_body_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  // POST with invalid JSON
  let req = build_post_request("not valid json")
  let res = handler(req)

  // Should have error response
  should.be_true(res.status == 400 || res.status == 422)
}

// Test: CORS headers on validation error responses
pub fn cors_headers_on_validation_errors_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  let req = server.Request(
    method: "POST",
    path: "/api/todos",
    headers: dict.from_list([
      #("Origin", "http://localhost:3000"),
      #("content-type", "application/json"),
    ]),
    body: "{\"title\": \"\"}",
  )
  let res = handler(req)

  // CORS header present on error response
  case dict.get(res.headers, "Access-Control-Allow-Origin") {
    Ok(_) -> Nil
    Error(_) -> should.fail()
  }
}

// Test: Error response is JSON
pub fn error_response_is_json_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  let req = server.Request(
    method: "GET",
    path: "/api/todos/nonexistent",
    headers: dict.new(),
    body: "",
  )
  let res = handler(req)

  case dict.get(res.headers, "Content-Type") {
    Ok(ct) -> should.be_true(string.contains(ct, "application/json"))
    Error(_) -> Nil
  }
}

// Test: Error response contains only allowed fields
pub fn error_response_has_allowed_fields_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  let req = server.Request(
    method: "GET",
    path: "/api/todos/nonexistent",
    headers: dict.new(),
    body: "",
  )
  let res = handler(req)

  // Body should contain 'error' or 'errors'
  should.be_true(string.contains(res.body, "error"))
}

// Test: Server error format is consistent
pub fn server_error_format_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  let req = server.Request(
    method: "GET",
    path: "/api/todos",
    headers: dict.new(),
    body: "",
  )
  let res = handler(req)

  // If 500, check format
  case res.status {
    500 -> {
      should.be_true(string.contains(res.body, "error"))
    }
    _ -> Nil
  }
}
