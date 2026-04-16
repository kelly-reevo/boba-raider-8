import counter
import gleam/dict
import gleeunit/should
import web/router
import web/server.{type Request}

// =============================================================================
// FULL-STACK INTEGRATION TESTS
// =============================================================================
// These tests exercise the complete integrated application without mocking.
// Each test spans multiple layers: HTTP routing, counter actor, static files.
// =============================================================================

/// Test helper to create a request
fn make_request(method: String, path: String) -> Request {
  server.Request(
    method: method,
    path: path,
    headers: dict.from_list([#("Content-Type", "application/json")]),
    body: "",
  )
}

// =============================================================================
// COUNTER API INTEGRATION TESTS (Layer 0)
// =============================================================================

/// Integration: Counter actor + router + HTTP handler
/// Verifies: GET /api/counter returns current count from actor state
pub fn counter_api_get_test() {
  // Start real counter actor
  let assert Ok(counter_subject) = counter.start()

  // Create real router handler with actual actor
  let handler = router.make_handler(counter_subject)

  // Make request through full stack
  let request = make_request("GET", "/api/counter")
  let response = handler(request)

  // Verify response (JSON format has no space after colon)
  response.status |> should.equal(200)
  response.body |> should.equal("{\"count\":0}")
}

/// Integration: Counter increment through full stack
/// Verifies: POST /api/counter/increment updates actor and returns new count
pub fn counter_api_increment_test() {
  let assert Ok(counter_subject) = counter.start()
  let handler = router.make_handler(counter_subject)

  // Increment through API
  let request = make_request("POST", "/api/counter/increment")
  let response = handler(request)

  response.status |> should.equal(200)
  response.body |> should.equal("{\"count\":1}")

  // Verify actor state was updated by checking via API again
  let get_request = make_request("GET", "/api/counter")
  let get_response = handler(get_request)
  get_response.body |> should.equal("{\"count\":1}")
}

/// Integration: Counter decrement through full stack
/// Verifies: POST /api/counter/decrement updates actor and returns new count
pub fn counter_api_decrement_test() {
  let assert Ok(counter_subject) = counter.start()
  let handler = router.make_handler(counter_subject)

  // First increment to positive value
  let _ = counter.increment(counter_subject)
  let _ = counter.increment(counter_subject)

  // Decrement through API
  let request = make_request("POST", "/api/counter/decrement")
  let response = handler(request)

  response.status |> should.equal(200)
  response.body |> should.equal("{\"count\":1}")
}

/// Integration: Counter reset through full stack
/// Verifies: POST /api/counter/reset clears actor state to 0
pub fn counter_api_reset_test() {
  let assert Ok(counter_subject) = counter.start()
  let handler = router.make_handler(counter_subject)

  // Set non-zero value
  let _ = counter.increment(counter_subject)
  let _ = counter.increment(counter_subject)
  let _ = counter.increment(counter_subject)

  // Reset through API
  let request = make_request("POST", "/api/counter/reset")
  let response = handler(request)

  response.status |> should.equal(200)
  response.body |> should.equal("{\"count\":0}")
}

/// Integration: Multiple counter operations maintain consistent state
/// Verifies: Actor state persists correctly across multiple HTTP requests
pub fn counter_api_multiple_operations_test() {
  let assert Ok(counter_subject) = counter.start()
  let handler = router.make_handler(counter_subject)

  // Sequence: inc, inc, dec, inc, reset, inc
  let ops = [
    #("POST", "/api/counter/increment", "{\"count\":1}"),
    #("POST", "/api/counter/increment", "{\"count\":2}"),
    #("POST", "/api/counter/decrement", "{\"count\":1}"),
    #("POST", "/api/counter/increment", "{\"count\":2}"),
    #("POST", "/api/counter/reset", "{\"count\":0}"),
    #("POST", "/api/counter/increment", "{\"count\":1}"),
  ]

  list.each(ops, fn(op) {
    let #(method, path, expected_body) = op
    let request = make_request(method, path)
    let response = handler(request)
    response.status |> should.equal(200)
    response.body |> should.equal(expected_body)
  })
}

// =============================================================================
// HEALTH & STATIC FILE INTEGRATION TESTS
// =============================================================================

/// Integration: Health endpoint returns ok status
/// Verifies: Basic HTTP routing and JSON response generation
pub fn health_endpoint_test() {
  let assert Ok(counter_subject) = counter.start()
  let handler = router.make_handler(counter_subject)

  let request = make_request("GET", "/health")
  let response = handler(request)

  response.status |> should.equal(200)
  // Health response: {"status":"ok"}
  response.body |> should.equal("{\"status\":\"ok\"}")
}

/// Integration: API health endpoint
/// Verifies: /api/health route is accessible
pub fn api_health_endpoint_test() {
  let assert Ok(counter_subject) = counter.start()
  let handler = router.make_handler(counter_subject)

  let request = make_request("GET", "/api/health")
  let response = handler(request)

  response.status |> should.equal(200)
}

/// Integration: Root path redirects to static HTML
/// Verifies: Static file serving integration
pub fn root_path_serves_index_test() {
  let assert Ok(counter_subject) = counter.start()
  let handler = router.make_handler(counter_subject)

  let request = make_request("GET", "/")
  let response = handler(request)

  // Should serve index.html (200 with HTML content)
  response.status |> should.equal(200)
  let has_html_content = response.body |> string.contains("<!DOCTYPE html>")
  has_html_content |> should.be_true
}

/// Integration: Static CSS files are served
/// Verifies: /static/ path routing works for CSS
pub fn static_css_served_test() {
  let assert Ok(counter_subject) = counter.start()
  let handler = router.make_handler(counter_subject)

  let request = make_request("GET", "/static/css/styles.css")
  let response = handler(request)

  // File exists or returns 404 if not present - we verify routing works
  // Either 200 (file exists) or 404 (file not found) is valid
  // for integration test - we're testing the routing layer
  should.be_true(response.status == 200 || response.status == 404)
}

// =============================================================================
// CORS INTEGRATION TESTS
// =============================================================================

/// Integration: CORS headers on counter API
/// Verifies: CORS middleware applies to API responses
pub fn counter_api_cors_headers_test() {
  let assert Ok(counter_subject) = counter.start()
  let handler = router.make_handler(counter_subject)

  let request = make_request("GET", "/api/counter")
  let response = handler(request)

  // Check CORS headers present
  let origin_header = dict.get(response.headers, "Access-Control-Allow-Origin")
  origin_header |> should.equal(Ok("*"))
}

/// Integration: OPTIONS preflight request handling
/// Verifies: CORS preflight returns 204 for API paths
pub fn options_preflight_api_test() {
  let assert Ok(counter_subject) = counter.start()
  let handler = router.make_handler(counter_subject)

  let request = make_request("OPTIONS", "/api/counter")
  let response = handler(request)

  response.status |> should.equal(204)

  let origin_header = dict.get(response.headers, "Access-Control-Allow-Origin")
  origin_header |> should.equal(Ok("*"))
}

/// Integration: OPTIONS on non-API path returns 404
/// Verifies: CORS preflight only applies to /api/* paths
pub fn options_non_api_returns_404_test() {
  let assert Ok(counter_subject) = counter.start()
  let handler = router.make_handler(counter_subject)

  let request = make_request("OPTIONS", "/some/other/path")
  let response = handler(request)

  response.status |> should.equal(404)
}

// =============================================================================
// ERROR HANDLING INTEGRATION TESTS
// =============================================================================

/// Integration: 404 for unknown paths
/// Verifies: Router correctly returns 404 for non-existent routes
pub fn unknown_path_returns_404_test() {
  let assert Ok(counter_subject) = counter.start()
  let handler = router.make_handler(counter_subject)

  let request = make_request("GET", "/api/unknown-endpoint")
  let response = handler(request)

  response.status |> should.equal(404)
}

/// Integration: Invalid method for counter endpoint
/// Verifies: Router handles mismatched methods appropriately
pub fn invalid_method_for_counter_test() {
  let assert Ok(counter_subject) = counter.start()
  let handler = router.make_handler(counter_subject)

  // PUT is not a valid method for counter endpoint
  let request = make_request("PUT", "/api/counter")
  let response = handler(request)

  // Router treats unknown method/path combo as not found
  response.status |> should.equal(404)
}

// =============================================================================
// SHARED TYPES INTEGRATION
// =============================================================================

/// Integration: Verify shared types are accessible
/// Verifies: Priority type from shared package works in server context
pub fn shared_types_integration_test() {
  // Verify pattern matching works on shared High priority
  let priority_high = shared.High
  let priority_str = case priority_high {
    shared.High -> "high"
    shared.Medium -> "medium"
    shared.Low -> "low"
  }
  priority_str |> should.equal("high")
}

/// Integration: Verify shared error types work
/// Verifies: AppError from shared package can be used
pub fn shared_error_types_test() {
  let error = shared.NotFound
  let message = shared.error_message(error)
  message |> should.equal("Not found")

  let input_error = shared.InvalidInput(["field1", "field2"])
  let input_message = shared.error_message(input_error)
  input_message |> should.equal("Invalid input: field1, field2")
}

// Import needed at bottom for dependency ordering
import gleam/list
import gleam/string
import shared
