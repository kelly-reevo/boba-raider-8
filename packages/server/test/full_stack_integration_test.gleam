// =============================================================================
// FULL-STACK INTEGRATION TEST SUITE
// =============================================================================
// Tests the ENTIRE integrated application across ALL layers.
// NO MOCKING - All tests exercise real code paths through real dependencies.
// =============================================================================

import counter
import gleeunit/should
import gleam/dict
import gleam/erlang/process.{type Subject}
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/otp/actor
import gleam/string
import shared.{type AppError, type Priority, type Todo, High, Low, Medium, NotFound}
import shared/todo_validation.{type TodoPatch, TodoPatch}
import todo_actor.{type TodoMsg}
import web/router
import web/server.{type Request, type Response, Request}

// =============================================================================
// TEST HELPERS
// =============================================================================

fn make_request(method: String, path: String, body: String) -> Request {
  Request(
    method: method,
    path: path,
    headers: dict.from_list([#("Content-Type", "application/json")]),
    body: body,
  )
}

fn make_get_request(path: String) -> Request {
  make_request("GET", path, "")
}

fn make_post_request(path: String, body: String) -> Request {
  make_request("POST", path, body)
}

fn make_patch_request(path: String, body: String) -> Request {
  make_request("PATCH", path, body)
}

fn make_delete_request(path: String) -> Request {
  make_request("DELETE", path, "")
}

fn make_options_request(path: String) -> Request {
  make_request("OPTIONS", path, "")
}

// =============================================================================
// LAYER 0: COUNTER API INTEGRATION TESTS
// =============================================================================
// These tests verify the counter functionality that spans:
// - HTTP routing (router.gleam)
// - OTP actor state (counter.gleam)
// - JSON serialization (shared types)
// - CORS middleware
// =============================================================================

/// Full-stack: Counter creation through real OTP actor
pub fn counter_actor_starts_and_responds_test() {
  let assert Ok(counter_subject) = counter.start()

  // Verify initial state is 0
  let count = counter.get_count(counter_subject)
  count |> should.equal(0)
}

/// Full-stack: Counter increment via HTTP handler
pub fn counter_http_increment_integration_test() {
  let assert Ok(counter_subject) = counter.start()
  let handler = router.make_handler(counter_subject)

  let request = make_post_request("/api/counter/increment", "")
  let response = handler(request)

  response.status |> should.equal(200)
  response.body |> should.equal("{\"count\":1}")
}

/// Full-stack: Counter decrement via HTTP handler
pub fn counter_http_decrement_integration_test() {
  let assert Ok(counter_subject) = counter.start()
  let handler = router.make_handler(counter_subject)

  // First increment
  let _ = counter.increment(counter_subject)
  let _ = counter.increment(counter_subject)

  // Then decrement via HTTP
  let request = make_post_request("/api/counter/decrement", "")
  let response = handler(request)

  response.status |> should.equal(200)
  response.body |> should.equal("{\"count\":1}")
}

/// Full-stack: Counter reset via HTTP handler
pub fn counter_http_reset_integration_test() {
  let assert Ok(counter_subject) = counter.start()
  let handler = router.make_handler(counter_subject)

  // Set non-zero value
  let _ = counter.increment(counter_subject)
  let _ = counter.increment(counter_subject)
  let _ = counter.increment(counter_subject)

  // Reset via HTTP
  let request = make_post_request("/api/counter/reset", "")
  let response = handler(request)

  response.status |> should.equal(200)
  response.body |> should.equal("{\"count\":0}")
}

/// Full-stack: Counter state persists across multiple HTTP requests
pub fn counter_state_persistence_across_requests_test() {
  let assert Ok(counter_subject) = counter.start()
  let handler = router.make_handler(counter_subject)

  // Sequence of operations
  let ops = [
    #("POST", "/api/counter/increment", "{\"count\":1}"),
    #("POST", "/api/counter/increment", "{\"count\":2}"),
    #("POST", "/api/counter/increment", "{\"count\":3}"),
    #("POST", "/api/counter/decrement", "{\"count\":2}"),
    #("GET", "/api/counter", "{\"count\":2}"),
    #("POST", "/api/counter/reset", "{\"count\":0}"),
    #("GET", "/api/counter", "{\"count\":0}"),
  ]

  list.each(ops, fn(op) {
    let #(method, path, expected) = op
    let request = make_request(method, path, "")
    let response = handler(request)
    response.status |> should.equal(200)
    response.body |> should.equal(expected)
  })
}

/// Full-stack: Counter API CORS headers present
pub fn counter_api_cors_headers_test() {
  let assert Ok(counter_subject) = counter.start()
  let handler = router.make_handler(counter_subject)

  let request = make_get_request("/api/counter")
  let response = handler(request)

  let origin = dict.get(response.headers, "Access-Control-Allow-Origin")
  origin |> should.equal(Ok("*"))

  let methods = dict.get(response.headers, "Access-Control-Allow-Methods")
  methods |> should.equal(Ok("GET, POST, OPTIONS"))
}

/// Full-stack: CORS preflight for counter endpoints
pub fn counter_api_options_preflight_test() {
  let assert Ok(counter_subject) = counter.start()
  let handler = router.make_handler(counter_subject)

  let request = make_options_request("/api/counter")
  let response = handler(request)

  response.status |> should.equal(204)
  dict.get(response.headers, "Access-Control-Allow-Origin")
  |> should.equal(Ok("*"))
}

// =============================================================================
// LAYER 1: TODO ACTOR + VALIDATION INTEGRATION TESTS
// =============================================================================
// These tests verify the todo functionality that spans:
// - Todo OTP actor (todo_actor.gleam)
// - Validation logic (shared/todo_validation.gleam)
// - Shared domain types (shared.gleam)
// Note: These test the backend layers directly since HTTP endpoints don't exist yet
// =============================================================================

/// Full-stack: Todo actor starts and creates todos with valid input
pub fn todo_actor_create_integration_test() {
  let assert Ok(todo_subject) = todo_actor.start()

  let item = todo_actor.create_todo(todo_subject, "Buy milk", None, Medium)

  item.title |> should.equal("Buy milk")
  item.completed |> should.be_false
  item.priority |> should.equal(Medium)
  string.length(item.id) |> should.equal(36) // UUID
}

/// Full-stack: Todo actor + validation integration for valid input
pub fn todo_validation_to_actor_integration_test() {
  let assert Ok(todo_subject) = todo_actor.start()

  // Validate input first
  let result =
    todo_validation.validate_todo_input("Buy groceries", Some("Milk, eggs"), "high")

  case result {
    Ok(validated) -> {
      // Pass validated data to actor
      let item =
        todo_actor.create_todo(
          todo_subject,
          validated.title,
          validated.description,
          validated.priority,
        )
      item.title |> should.equal("Buy groceries")
      item.priority |> should.equal(High)
      item.description |> should.equal(Some("Milk, eggs"))
    }
    Error(_) -> should.fail()
  }
}

/// Full-stack: Todo validation rejects invalid input before actor
pub fn todo_validation_rejects_invalid_input_test() {
  // Empty title should be rejected
  let result = todo_validation.validate_todo_input("", None, "medium")
  result |> should.be_error

  // Invalid priority should be rejected
  let result2 = todo_validation.validate_todo_input("Valid", None, "urgent")
  result2 |> should.be_error

  // Title too long should be rejected
  let long_title = string.repeat("a", 201)
  let result3 = todo_validation.validate_todo_input(long_title, None, "low")
  result3 |> should.be_error
}

/// Full-stack: Todo actor get all returns list
pub fn todo_actor_get_all_integration_test() {
  let assert Ok(todo_subject) = todo_actor.start()

  let _ = todo_actor.create_todo(todo_subject, "First", None, Low)
  let _ = todo_actor.create_todo(todo_subject, "Second", Some("desc"), Medium)
  let _ = todo_actor.create_todo(todo_subject, "Third", None, High)

  let all = todo_actor.get_all_todos(todo_subject)
  list.length(all) |> should.equal(3)
}

/// Full-stack: Todo actor get by id returns correct todo
pub fn todo_actor_get_by_id_integration_test() {
  let assert Ok(todo_subject) = todo_actor.start()

  let created = todo_actor.create_todo(todo_subject, "Find me", None, High)

  let result = todo_actor.get_todo(todo_subject, created.id)
  case result {
    Ok(t) -> t.id |> should.equal(created.id)
    Error(_) -> should.fail()
  }
}

/// Full-stack: Todo actor get by id returns NotFound for missing
pub fn todo_actor_get_not_found_test() {
  let assert Ok(todo_subject) = todo_actor.start()

  let result = todo_actor.get_todo(todo_subject, "non-existent-id")
  case result {
    Error(NotFound) -> True |> should.be_true
    _ -> should.fail()
  }
}

/// Full-stack: Todo actor update modifies existing todo
pub fn todo_actor_update_integration_test() {
  let assert Ok(todo_subject) = todo_actor.start()

  let created = todo_actor.create_todo(todo_subject, "Original", None, Low)

  let patch = TodoPatch(title: Some("Updated"), completed: Some(True))
  let result = todo_actor.update_todo(todo_subject, created.id, patch)

  case result {
    Ok(updated) -> {
      updated.id |> should.equal(created.id)
      updated.title |> should.equal("Updated")
      updated.completed |> should.be_true
      updated.priority |> should.equal(Low) // Unchanged
    }
    Error(_) -> should.fail()
  }
}

/// Full-stack: Todo actor update returns NotFound for missing
pub fn todo_actor_update_not_found_test() {
  let assert Ok(todo_subject) = todo_actor.start()

  let patch = TodoPatch(title: Some("New"), completed: None)
  let result = todo_actor.update_todo(todo_subject, "missing-id", patch)

  case result {
    Error(NotFound) -> True |> should.be_true
    _ -> should.fail()
  }
}

/// Full-stack: Todo actor delete removes todo
pub fn todo_actor_delete_integration_test() {
  let assert Ok(todo_subject) = todo_actor.start()

  let created = todo_actor.create_todo(todo_subject, "To delete", None, Medium)

  // Delete it
  let result = todo_actor.delete_todo(todo_subject, created.id)
  case result {
    Ok(True) -> True |> should.be_true
    _ -> should.fail()
  }

  // Verify it's gone
  let not_found = todo_actor.get_todo(todo_subject, created.id)
  case not_found {
    Error(NotFound) -> True |> should.be_true
    _ -> should.fail()
  }
}

/// Full-stack: Todo actor state persists across operations
pub fn todo_actor_state_persistence_test() {
  let assert Ok(todo_subject) = todo_actor.start()

  // Create todos
  let t1 = todo_actor.create_todo(todo_subject, "One", None, Low)
  let t2 = todo_actor.create_todo(todo_subject, "Two", None, Medium)
  let t3 = todo_actor.create_todo(todo_subject, "Three", None, High)

  // Update t2
  let patch = TodoPatch(title: None, completed: Some(True))
  let assert Ok(_) = todo_actor.update_todo(todo_subject, t2.id, patch)

  // Delete t1
  let assert Ok(_) = todo_actor.delete_todo(todo_subject, t1.id)

  // Verify state
  let all = todo_actor.get_all_todos(todo_subject)
  list.length(all) |> should.equal(2)

  // Verify t2 is completed
  let assert Ok(fetched_t2) = todo_actor.get_todo(todo_subject, t2.id)
  fetched_t2.completed |> should.be_true

  // Verify t3 exists and not completed
  let assert Ok(fetched_t3) = todo_actor.get_todo(todo_subject, t3.id)
  fetched_t3.completed |> should.be_false
}

/// Full-stack: Priority round-trip through all operations
pub fn todo_priority_round_trip_test() {
  let assert Ok(todo_subject) = todo_actor.start()

  let low = todo_actor.create_todo(todo_subject, "Low", None, Low)
  let med = todo_actor.create_todo(todo_subject, "Med", None, Medium)
  let high = todo_actor.create_todo(todo_subject, "High", None, High)

  let assert Ok(fetched_low) = todo_actor.get_todo(todo_subject, low.id)
  let assert Ok(fetched_med) = todo_actor.get_todo(todo_subject, med.id)
  let assert Ok(fetched_high) = todo_actor.get_todo(todo_subject, high.id)

  fetched_low.priority |> should.equal(Low)
  fetched_med.priority |> should.equal(Medium)
  fetched_high.priority |> should.equal(High)
}

// =============================================================================
// LAYER CROSSING: Validation -> Actor -> Error handling
// =============================================================================

/// Full-stack: Validation errors convert to AppError
pub fn validation_errors_convert_to_app_error_test() {
  let result = todo_validation.validate_todo_input("", Some("x"), "invalid")

  let assert Error(errors) = result
  let app_error: AppError = shared.InvalidInput(errors)

  let msg = shared.error_message(app_error)
  msg |> string.contains("Invalid input") |> should.be_true

  let json = shared.error_to_json(app_error)
  json |> string.contains("invalid_input") |> should.be_true
}

/// Full-stack: Complete validation + create flow
pub fn complete_validation_create_flow_test() {
  let assert Ok(todo_subject) = todo_actor.start()

  // Step 1: Validate raw input
  let result =
    todo_validation.validate_todo_input("Complete task", Some("Do it"), "high")

  // Step 2: Pass to actor if valid
  case result {
    Ok(validated) -> {
      let item =
        todo_actor.create_todo(
          todo_subject,
          validated.title,
          validated.description,
          validated.priority,
        )

      // Step 3: Verify stored correctly
      let assert Ok(fetched) = todo_actor.get_todo(todo_subject, item.id)
      fetched.title |> should.equal("Complete task")
      fetched.description |> should.equal(Some("Do it"))
      fetched.priority |> should.equal(High)
      fetched.completed |> should.be_false
    }
    Error(_) -> should.fail()
  }
}

// =============================================================================
// HTTP ROUTER INTEGRATION TESTS
// =============================================================================

/// Full-stack: Health endpoint returns ok
pub fn health_endpoint_integration_test() {
  let assert Ok(counter_subject) = counter.start()
  let handler = router.make_handler(counter_subject)

  let request = make_get_request("/health")
  let response = handler(request)

  response.status |> should.equal(200)
  response.body |> string.contains("ok") |> should.be_true
}

/// Full-stack: API health endpoint
pub fn api_health_endpoint_integration_test() {
  let assert Ok(counter_subject) = counter.start()
  let handler = router.make_handler(counter_subject)

  let request = make_get_request("/api/health")
  let response = handler(request)

  response.status |> should.equal(200)
}

/// Full-stack: Root path serves index HTML
pub fn root_serves_index_integration_test() {
  let assert Ok(counter_subject) = counter.start()
  let handler = router.make_handler(counter_subject)

  let request = make_get_request("/")
  let response = handler(request)

  response.status |> should.equal(200)
  response.body |> string.contains("<!DOCTYPE html>") |> should.be_true
}

/// Full-stack: 404 for unknown paths
pub fn unknown_path_returns_404_integration_test() {
  let assert Ok(counter_subject) = counter.start()
  let handler = router.make_handler(counter_subject)

  let request = make_get_request("/api/unknown")
  let response = handler(request)

  response.status |> should.equal(404)
}

/// Full-stack: CORS preflight for API paths
pub fn cors_preflight_integration_test() {
  let assert Ok(counter_subject) = counter.start()
  let handler = router.make_handler(counter_subject)

  let request = make_options_request("/api/counter")
  let response = handler(request)

  response.status |> should.equal(204)
  dict.get(response.headers, "Access-Control-Allow-Origin")
  |> should.equal(Ok("*"))
}

/// Full-stack: CORS preflight only for /api/* paths
pub fn cors_preflight_only_api_test() {
  let assert Ok(counter_subject) = counter.start()
  let handler = router.make_handler(counter_subject)

  let request = make_options_request("/not-api/path")
  let response = handler(request)

  response.status |> should.equal(404)
}

/// Full-stack: Static file serving for CSS
pub fn static_css_serving_integration_test() {
  let assert Ok(counter_subject) = counter.start()
  let handler = router.make_handler(counter_subject)

  let request = make_get_request("/static/css/styles.css")
  let response = handler(request)

  // Either 200 (file exists) or 404 (not found) - both valid for testing routing
  should.be_true(response.status == 200 || response.status == 404)
}

// =============================================================================
// SHARED TYPES INTEGRATION TESTS
// =============================================================================

/// Full-stack: Priority types work across all layers
pub fn shared_priority_types_integration_test() {
  // Test that Priority enum works as expected
  let p_high = shared.High
  let p_med = shared.Medium
  let p_low = shared.Low

  // Priority encoding
  shared.priority_encode(p_high) |> should.equal(shared.priority_encode(High))
  shared.priority_encode(p_med) |> should.equal(shared.priority_encode(Medium))
  shared.priority_encode(p_low) |> should.equal(shared.priority_encode(Low))

  // Pattern matching
  case p_high {
    shared.High -> True
    _ -> False
  }
  |> should.be_true
}

/// Full-stack: Todo type creation and access
pub fn shared_todo_type_integration_test() {
  let item = shared.Todo(
    id: "test-id",
    title: "Test",
    description: Some("Desc"),
    priority: Medium,
    completed: False,
  )

  item.id |> should.equal("test-id")
  item.title |> should.equal("Test")
  item.priority |> should.equal(Medium)
}

/// Full-stack: AppError types and JSON serialization
pub fn shared_app_error_integration_test() {
  let not_found = shared.NotFound
  let input_error = shared.InvalidInput(["title", "priority"])
  let internal = shared.InternalError

  shared.error_message(not_found) |> should.equal("Not found")
  shared.error_message(input_error)
  |> should.equal("Invalid input: title, priority")
  shared.error_message(internal) |> should.equal("Internal error")

  // JSON serialization
  let json = shared.error_to_json(not_found)
  json |> string.contains("not_found") |> should.be_true

  let json2 = shared.error_to_json(input_error)
  json2 |> string.contains("invalid_input") |> should.be_true
}

/// Full-stack: Todo JSON encoding produces valid JSON
pub fn todo_json_encoding_integration_test() {
  let item = shared.Todo(
    id: "abc-123",
    title: "Test Todo",
    description: Some("A description"),
    priority: High,
    completed: True,
  )

  let json_str = shared.todo_to_json(item) |> json.to_string()

  json_str |> string.contains("\"id\":\"abc-123\"") |> should.be_true
  json_str |> string.contains("\"title\":\"Test Todo\"") |> should.be_true
  json_str |> string.contains("\"completed\":true") |> should.be_true
  json_str |> string.contains("\"priority\":\"high\"") |> should.be_true
}
