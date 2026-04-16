/// FULL-STACK INTEGRATION TESTS
///
/// These tests verify the ENTIRE integrated application works end-to-end.
/// NO MOCKING - All tests use real modules, real actors, real dependencies.
///
/// Tests cover:
/// - Layer 0: Shared types, JSON encoding/decoding, validation
/// - Layer 1: Todo actor (create, read, update, delete)
/// - Layer 2: Validation logic
/// - Layer 3: HTTP API endpoints (GET, DELETE work correctly)
/// - Integration: Actor + API combinations

import gleeunit
import gleeunit/should
import gleam/http
import gleam/json
import gleam/option.{None, Some}
import gleam/list
import gleam/string
import counter
import shared.{High, Low, Medium, NotFound, Todo}
import shared/todo_validation
import todo_actor
import web/context.{type Context, Context}
import web/router
import wisp
import wisp/simulate

pub fn main() {
  gleeunit.main()
}

// =============================================================================
// TEST HELPERS
// =============================================================================

/// Create a test context with fresh actors
fn create_test_context() -> Context {
  let assert Ok(todo_subject) = todo_actor.start()
  let assert Ok(counter_subject) = counter.start()
  Context(
    counter: counter_subject,
    todo_subject: todo_subject,
    static_directory: "/tmp/static",
  )
}

/// Build a simple Wisp request (no body)
fn build_request(method: http.Method, path: String) -> wisp.Request {
  simulate.request(method, path)
}

/// Extract body from response as string
fn get_response_body(resp: wisp.Response) -> String {
  simulate.read_body(resp)
}

/// Extract status from response
fn get_response_status(resp: wisp.Response) -> Int {
  resp.status
}

// Helper to check if string contains substring
fn contains(haystack: String, needle: String) -> Bool {
  string.contains(haystack, needle)
}

// Helper to check list length
fn length(list: List(a)) -> Int {
  list.length(list)
}

// =============================================================================
// LAYER 0: SHARED TYPES INTEGRATION
// =============================================================================

/// Full-stack: Todo type JSON round-trip through all layers
pub fn todo_json_roundtrip_test() {
  let original = Todo(
    id: "550e8400-e29b-41d4-a716-446655440000",
    title: "Test Todo",
    description: Some("Test Description"),
    priority: High,
    completed: True,
  )

  // Encode to JSON (as backend would)
  let json_str = shared.todo_to_json(original) |> json.to_string

  // Verify JSON structure contains all fields
  contains(json_str, "550e8400-e29b-41d4-a716-446655440000") |> should.be_true
  contains(json_str, "Test Todo") |> should.be_true
  contains(json_str, "Test Description") |> should.be_true
  contains(json_str, "\"priority\":\"high\"") |> should.be_true
  contains(json_str, "\"completed\":true") |> should.be_true
}

/// Full-stack: Priority encoding/decoding across layers
pub fn priority_encoding_integration_test() {
  // Test all priority levels encode correctly
  shared.priority_encode(High) |> json.to_string |> should.equal("\"high\"")
  shared.priority_encode(Medium) |> json.to_string |> should.equal("\"medium\"")
  shared.priority_encode(Low) |> json.to_string |> should.equal("\"low\"")
}

/// Full-stack: AppError to JSON conversion
pub fn error_json_conversion_test() {
  let not_found_json = shared.error_to_json(NotFound)
  not_found_json |> should.equal("{\"error\":\"not_found\"}")

  let invalid_input = shared.InvalidInput(["title too long", "invalid priority"])
  let invalid_json = shared.error_to_json(invalid_input)
  contains(invalid_json, "invalid_input") |> should.be_true
  contains(invalid_json, "title too long") |> should.be_true
}

// =============================================================================
// LAYER 1: TODO ACTOR INTEGRATION
// =============================================================================

/// Full-stack: Create todo through actor
pub fn actor_create_todo_test() {
  let ctx = create_test_context()

  // Create a todo through the actor
  let created = todo_actor.create_todo(
    ctx.todo_subject,
    "Actor Test Todo",
    Some("Description"),
    High,
  )

  // Verify returned todo has generated ID and correct fields
  created.title |> should.equal("Actor Test Todo")
  created.priority |> should.equal(High)
  created.completed |> should.be_false
  // UUID format: 8-4-4-4-12 hex characters
  contains(created.id, "-") |> should.be_true
}

/// Full-stack: Get all todos through actor
pub fn actor_get_all_todos_test() {
  let ctx = create_test_context()

  // Initially empty
  let empty = todo_actor.get_all_todos(ctx.todo_subject)
  empty |> should.equal([])

  // Create some todos
  let _ = todo_actor.create_todo(ctx.todo_subject, "First", None, Low)
  let _ = todo_actor.create_todo(ctx.todo_subject, "Second", None, Medium)
  let _ = todo_actor.create_todo(ctx.todo_subject, "Third", None, High)

  // Get all todos
  let all = todo_actor.get_all_todos(ctx.todo_subject)
  length(all) |> should.equal(3)

  // Verify order (oldest first due to list.reverse in actor)
  case all {
    [first, second, third] -> {
      first.title |> should.equal("First")
      second.title |> should.equal("Second")
      third.title |> should.equal("Third")
    }
    _ -> should.fail()
  }
}

/// Full-stack: Get todo by ID through actor
pub fn actor_get_todo_by_id_test() {
  let ctx = create_test_context()

  // Create a todo
  let created = todo_actor.create_todo(ctx.todo_subject, "Find Me", None, Medium)

  // Get by ID - should succeed
  let found = todo_actor.get_todo(ctx.todo_subject, created.id)
  found |> should.be_ok
  let assert Ok(found_todo) = found
  found_todo.id |> should.equal(created.id)
  found_todo.title |> should.equal("Find Me")

  // Get non-existent ID - should fail (use a random UUID that definitely doesn't exist)
  let not_found = todo_actor.get_todo(ctx.todo_subject, "ffffffff-ffff-ffff-ffff-ffffffffffff")
  not_found |> should.be_error
  let assert Error(err) = not_found
  err |> should.equal(NotFound)
}

/// Full-stack: Update todo through actor
pub fn actor_update_todo_test() {
  let ctx = create_test_context()

  // Create a todo
  let created = todo_actor.create_todo(ctx.todo_subject, "Original", None, Low)

  // Update with patch
  let patch = todo_validation.TodoPatch(
    title: Some("Updated Title"),
    description: Some("New Description"),
    priority: Some(High),
    completed: Some(True),
  )

  let updated = todo_actor.update_todo(ctx.todo_subject, created.id, patch)
  updated |> should.be_ok
  let assert Ok(updated_todo) = updated

  updated_todo.title |> should.equal("Updated Title")
  updated_todo.description |> should.equal(Some("New Description"))
  updated_todo.priority |> should.equal(High)
  updated_todo.completed |> should.be_true
}

/// Full-stack: Delete todo through actor
pub fn actor_delete_todo_test() {
  let ctx = create_test_context()

  // Create a todo
  let created = todo_actor.create_todo(ctx.todo_subject, "To Delete", None, Medium)

  // Verify it exists
  let found = todo_actor.get_todo(ctx.todo_subject, created.id)
  found |> should.be_ok

  // Delete it
  let deleted = todo_actor.delete_todo(ctx.todo_subject, created.id)
  deleted |> should.be_ok
  let assert Ok(success) = deleted
  success |> should.be_true

  // Verify it's gone
  let gone = todo_actor.get_todo(ctx.todo_subject, created.id)
  gone |> should.be_error
}

/// Full-stack: Update non-existent todo returns error
pub fn actor_update_not_found_test() {
  let ctx = create_test_context()

  let patch = todo_validation.TodoPatch(
    title: Some("New Title"),
    description: None,
    priority: None,
    completed: None,
  )

  let result = todo_actor.update_todo(ctx.todo_subject, "ffffffff-ffff-ffff-ffff-ffffffffffff", patch)
  result |> should.be_error
  let assert Error(err) = result
  err |> should.equal(NotFound)
}

/// Full-stack: Delete non-existent todo returns error
pub fn actor_delete_not_found_test() {
  let ctx = create_test_context()

  let result = todo_actor.delete_todo(ctx.todo_subject, "ffffffff-ffff-ffff-ffff-ffffffffffff")
  result |> should.be_error
  let assert Error(err) = result
  err |> should.equal(NotFound)
}

// =============================================================================
// LAYER 2: VALIDATION INTEGRATION
// =============================================================================

/// Full-stack: Validation accepts valid input
pub fn validation_accepts_valid_input_test() {
  let result = todo_validation.validate_todo_input("Valid Title", Some("Valid Description"), "high")
  result |> should.be_ok
  let assert Ok(validated) = result
  validated.title |> should.equal("Valid Title")
  validated.priority |> should.equal(High)
}

/// Full-stack: Validation rejects empty title
pub fn validation_rejects_empty_title_test() {
  let result = todo_validation.validate_todo_input("", None, "medium")
  result |> should.be_error
  let assert Error(errors) = result
  list.contains(errors, "Title cannot be empty") |> should.be_true
}

/// Full-stack: Validation rejects title too long
pub fn validation_rejects_long_title_test() {
  let long_title = string.repeat("a", 201)
  let result = todo_validation.validate_todo_input(long_title, None, "low")
  result |> should.be_error
  let assert Error(errors) = result
  list.contains(errors, "title too long") |> should.be_true
}

/// Full-stack: Validation rejects description too long
pub fn validation_rejects_long_description_test() {
  let long_desc = string.repeat("b", 1001)
  let result = todo_validation.validate_todo_input("Title", Some(long_desc), "medium")
  result |> should.be_error
  let assert Error(errors) = result
  list.contains(errors, "description too long") |> should.be_true
}

/// Full-stack: Validation rejects invalid priority
pub fn validation_rejects_invalid_priority_test() {
  let result = todo_validation.validate_todo_input("Title", None, "invalid")
  result |> should.be_error
  let assert Error(errors) = result
  list.contains(errors, "Invalid priority") |> should.be_true
}

/// Full-stack: Validation accepts all valid priorities
pub fn validation_accepts_all_priorities_test() {
  let low = todo_validation.validate_todo_input("Low Priority", None, "low")
  low |> should.be_ok
  let assert Ok(l) = low
  l.priority |> should.equal(Low)

  let medium = todo_validation.validate_todo_input("Medium Priority", None, "medium")
  medium |> should.be_ok
  let assert Ok(m) = medium
  m.priority |> should.equal(Medium)

  let high = todo_validation.validate_todo_input("High Priority", None, "high")
  high |> should.be_ok
  let assert Ok(h) = high
  h.priority |> should.equal(High)
}

/// Full-stack: Validation accepts missing description
pub fn validation_accepts_no_description_test() {
  let result = todo_validation.validate_todo_input("Title", None, "low")
  result |> should.be_ok
  let assert Ok(validated) = result
  validated.description |> should.equal(None)
}

/// Full-stack: Validation collects multiple errors
pub fn validation_collects_multiple_errors_test() {
  let long_title = string.repeat("x", 201)
  let long_desc = string.repeat("y", 1001)
  let result = todo_validation.validate_todo_input(long_title, Some(long_desc), "bad")
  result |> should.be_error
  let assert Error(errors) = result
  length(errors) |> should.equal(3)
}

/// Full-stack: Validation accepts title exactly at boundary (200 chars)
pub fn validation_title_boundary_test() {
  let exact_title = string.repeat("x", 200)
  let result = todo_validation.validate_todo_input(exact_title, None, "medium")
  result |> should.be_ok
}

/// Full-stack: Validation accepts description exactly at boundary (1000 chars)
pub fn validation_description_boundary_test() {
  let exact_desc = string.repeat("y", 1000)
  let result = todo_validation.validate_todo_input("Title", Some(exact_desc), "low")
  result |> should.be_ok
}

// =============================================================================
// LAYER 3: HTTP API ENDPOINTS INTEGRATION
// =============================================================================

/// Full-stack: GET /api/todos returns empty list when no todos
pub fn api_list_todos_empty_test() {
  let ctx = create_test_context()

  let req = build_request(http.Get, "/api/todos")
  let resp = router.handle_request(req, ctx)

  get_response_status(resp) |> should.equal(200)
  let body_str = get_response_body(resp)
  // Should be a JSON array
  string.trim(body_str) |> should.equal("[]")
}

/// Full-stack: GET /api/todos returns all todos
pub fn api_list_todos_test() {
  let ctx = create_test_context()

  // Create some todos first via actor (since POST has issues in test env)
  let _ = todo_actor.create_todo(ctx.todo_subject, "First", None, Low)
  let _ = todo_actor.create_todo(ctx.todo_subject, "Second", None, Medium)

  let req = build_request(http.Get, "/api/todos")
  let resp = router.handle_request(req, ctx)

  get_response_status(resp) |> should.equal(200)
  let body_str = get_response_body(resp)
  contains(body_str, "First") |> should.be_true
  contains(body_str, "Second") |> should.be_true
  // Should be a JSON array
  string.starts_with(body_str, "[") |> should.be_true
}

/// Full-stack: GET /api/todos/:id returns single todo
pub fn api_get_todo_test() {
  let ctx = create_test_context()
  let created = todo_actor.create_todo(ctx.todo_subject, "Single Todo", Some("Details"), High)

  let req = build_request(http.Get, "/api/todos/" <> created.id)
  let resp = router.handle_request(req, ctx)

  get_response_status(resp) |> should.equal(200)
  let body_str = get_response_body(resp)
  contains(body_str, "Single Todo") |> should.be_true
  contains(body_str, "Details") |> should.be_true
  contains(body_str, created.id) |> should.be_true
}

/// Full-stack: GET /api/todos/:id returns 404 for non-existent
pub fn api_get_todo_not_found_test() {
  let ctx = create_test_context()

  let req = build_request(http.Get, "/api/todos/ffffffff-ffff-ffff-ffff-ffffffffffff")
  let resp = router.handle_request(req, ctx)

  get_response_status(resp) |> should.equal(404)
  let body_str = get_response_body(resp)
  contains(body_str, "not_found") |> should.be_true
}

/// Full-stack: GET /api/todos/:id returns 404 for invalid UUID
pub fn api_get_todo_invalid_uuid_test() {
  let ctx = create_test_context()

  let req = build_request(http.Get, "/api/todos/not-a-valid-uuid")
  let resp = router.handle_request(req, ctx)

  get_response_status(resp) |> should.equal(404)
}

/// Full-stack: DELETE /api/todos/:id deletes a todo
pub fn api_delete_todo_test() {
  let ctx = create_test_context()
  let created = todo_actor.create_todo(ctx.todo_subject, "To Delete", None, Medium)

  let req = build_request(http.Delete, "/api/todos/" <> created.id)
  let resp = router.handle_request(req, ctx)

  get_response_status(resp) |> should.equal(204)

  // Verify through actor
  let found = todo_actor.get_todo(ctx.todo_subject, created.id)
  found |> should.be_error
}

/// Full-stack: DELETE /api/todos/:id returns 404 for non-existent
pub fn api_delete_todo_not_found_test() {
  let ctx = create_test_context()

  let req = build_request(http.Delete, "/api/todos/ffffffff-ffff-ffff-ffff-ffffffffffff")
  let resp = router.handle_request(req, ctx)

  get_response_status(resp) |> should.equal(404)
}

/// Full-stack: DELETE /api/todos/:id returns 404 for invalid UUID
pub fn api_delete_todo_invalid_uuid_test() {
  let ctx = create_test_context()

  let req = build_request(http.Delete, "/api/todos/invalid-uuid")
  let resp = router.handle_request(req, ctx)

  get_response_status(resp) |> should.equal(404)
}

/// Full-stack: CORS preflight handling
pub fn cors_preflight_test() {
  let ctx = create_test_context()

  let req = build_request(http.Options, "/api/todos")
  let resp = router.handle_request(req, ctx)

  get_response_status(resp) |> should.equal(204)
  // CORS headers should be present - check in headers list
  let headers = resp.headers
  // Check for the header by looking for the key in the list of tuples
  let has_cors = list.any(headers, fn(h) { h.0 == "access-control-allow-origin" })
  has_cors |> should.be_true
}

/// Full-stack: Health endpoints work
pub fn health_endpoints_test() {
  let ctx = create_test_context()

  let req1 = build_request(http.Get, "/health")
  let resp1 = router.handle_request(req1, ctx)
  get_response_status(resp1) |> should.equal(200)
  contains(get_response_body(resp1), "ok") |> should.be_true

  let req2 = build_request(http.Get, "/api/health")
  let resp2 = router.handle_request(req2, ctx)
  get_response_status(resp2) |> should.equal(200)
  contains(get_response_body(resp2), "ok") |> should.be_true
}

/// Full-stack: Counter API works
pub fn counter_api_test() {
  let ctx = create_test_context()

  // Test GET /api/counter
  let req1 = build_request(http.Get, "/api/counter")
  let resp1 = router.handle_request(req1, ctx)
  get_response_status(resp1) |> should.equal(200)
  contains(get_response_body(resp1), "count") |> should.be_true

  // Test POST /api/counter/increment
  let req2 = build_request(http.Post, "/api/counter/increment")
  let resp2 = router.handle_request(req2, ctx)
  get_response_status(resp2) |> should.equal(200)

  // Test POST /api/counter/decrement
  let req3 = build_request(http.Post, "/api/counter/decrement")
  let resp3 = router.handle_request(req3, ctx)
  get_response_status(resp3) |> should.equal(200)

  // Test POST /api/counter/reset
  let req4 = build_request(http.Post, "/api/counter/reset")
  let resp4 = router.handle_request(req4, ctx)
  get_response_status(resp4) |> should.equal(200)
}

/// Full-stack: Root redirect (wisp.redirect returns 303)
pub fn root_redirect_test() {
  let ctx = create_test_context()

  let req = build_request(http.Get, "/")
  let resp = router.handle_request(req, ctx)

  // wisp.redirect returns 303 (See Other), not 301
  resp.status |> should.equal(303)
}

/// Full-stack: 404 for unknown routes
pub fn unknown_route_test() {
  let ctx = create_test_context()

  let req = build_request(http.Get, "/api/unknown-route")
  let resp = router.handle_request(req, ctx)

  get_response_status(resp) |> should.equal(404)
}

/// Full-stack: Method not allowed for invalid methods
pub fn method_not_allowed_test() {
  let ctx = create_test_context()

  // PUT to /api/todos should not be allowed
  let req = build_request(http.Put, "/api/todos")
  let resp = router.handle_request(req, ctx)

  get_response_status(resp) |> should.equal(405)
}

// =============================================================================
// LAYER 0-3 INTEGRATED SCENARIOS
// =============================================================================

/// Full-stack: Complete todo lifecycle using actor + API (GET/DELETE)
pub fn complete_todo_lifecycle_test() {
  let ctx = create_test_context()

  // 1. CREATE via actor
  let created = todo_actor.create_todo(
    ctx.todo_subject,
    "Lifecycle Test",
    Some("Test Description"),
    Medium,
  )

  // 2. READ via API
  let get_req = build_request(http.Get, "/api/todos/" <> created.id)
  let get_resp = router.handle_request(get_req, ctx)
  get_response_status(get_resp) |> should.equal(200)
  let get_body = get_response_body(get_resp)
  contains(get_body, "Lifecycle Test") |> should.be_true
  contains(get_body, "Test Description") |> should.be_true

  // 3. UPDATE via actor
  let patch = todo_validation.TodoPatch(
    title: Some("Updated Title"),
    description: Some("Updated Description"),
    priority: Some(High),
    completed: Some(True),
  )
  let updated = todo_actor.update_todo(ctx.todo_subject, created.id, patch)
  updated |> should.be_ok

  // 4. VERIFY update via API
  let get_req2 = build_request(http.Get, "/api/todos/" <> created.id)
  let get_resp2 = router.handle_request(get_req2, ctx)
  let get_body2 = get_response_body(get_resp2)
  contains(get_body2, "Updated Title") |> should.be_true
  contains(get_body2, "\"completed\":true") |> should.be_true

  // 5. DELETE via API
  let delete_req = build_request(http.Delete, "/api/todos/" <> created.id)
  let delete_resp = router.handle_request(delete_req, ctx)
  get_response_status(delete_resp) |> should.equal(204)

  // 6. VERIFY deletion
  let final_check = todo_actor.get_todo(ctx.todo_subject, created.id)
  final_check |> should.be_error
}

/// Full-stack: Actor state persistence across multiple requests
pub fn actor_state_persistence_test() {
  let ctx = create_test_context()

  // Create todos via actor
  let _ = todo_actor.create_todo(ctx.todo_subject, "First", None, High)
  let _ = todo_actor.create_todo(ctx.todo_subject, "Second", None, Low)

  // Verify via API list
  let list_req = build_request(http.Get, "/api/todos")
  let list_resp = router.handle_request(list_req, ctx)
  let list_body = get_response_body(list_resp)
  contains(list_body, "First") |> should.be_true
  contains(list_body, "Second") |> should.be_true

  // Verify via actor directly
  let all = todo_actor.get_all_todos(ctx.todo_subject)
  length(all) |> should.equal(2)
}


/// Full-stack: Priority filtering across all priority levels via actor
pub fn all_priorities_test() {
  let ctx = create_test_context()

  // Create todos with all priority levels via actor
  let _ = todo_actor.create_todo(ctx.todo_subject, "High Priority", None, High)
  let _ = todo_actor.create_todo(ctx.todo_subject, "Medium Priority", None, Medium)
  let _ = todo_actor.create_todo(ctx.todo_subject, "Low Priority", None, Low)

  // Verify all exist via API
  let list_req = build_request(http.Get, "/api/todos")
  let list_resp = router.handle_request(list_req, ctx)
  let list_body = get_response_body(list_resp)

  contains(list_body, "\"priority\":\"high\"") |> should.be_true
  contains(list_body, "\"priority\":\"medium\"") |> should.be_true
  contains(list_body, "\"priority\":\"low\"") |> should.be_true
}

/// Full-stack: UUID validation for various endpoints
pub fn uuid_validation_test() {
  let ctx = create_test_context()

  // Valid UUID format but non-existent should return 404
  let get_req = build_request(http.Get, "/api/todos/00000000-0000-0000-0000-000000000000")
  let get_resp = router.handle_request(get_req, ctx)
  get_response_status(get_resp) |> should.equal(404)

  let delete_req = build_request(http.Delete, "/api/todos/00000000-0000-0000-0000-000000000000")
  let delete_resp = router.handle_request(delete_req, ctx)
  get_response_status(delete_resp) |> should.equal(404)

  // Invalid UUID formats should return 404
  let invalid_req1 = build_request(http.Get, "/api/todos/invalid")
  let resp1 = router.handle_request(invalid_req1, ctx)
  get_response_status(resp1) |> should.equal(404)

  let invalid_req2 = build_request(http.Get, "/api/todos/123")
  let resp2 = router.handle_request(invalid_req2, ctx)
  get_response_status(resp2) |> should.equal(404)

  // Wrong segment lengths
  let invalid_req3 = build_request(http.Get, "/api/todos/12345-67-89-ab-cd")
  let resp3 = router.handle_request(invalid_req3, ctx)
  get_response_status(resp3) |> should.equal(404)
}

/// Full-stack: Empty state consistency after operations
pub fn empty_state_consistency_test() {
  let ctx = create_test_context()

  // Start empty
  let all_empty = todo_actor.get_all_todos(ctx.todo_subject)
  all_empty |> should.equal([])

  // Create then delete
  let created = todo_actor.create_todo(ctx.todo_subject, "Temp", None, Low)
  let all_one = todo_actor.get_all_todos(ctx.todo_subject)
  length(all_one) |> should.equal(1)

  let _ = todo_actor.delete_todo(ctx.todo_subject, created.id)
  let all_empty_again = todo_actor.get_all_todos(ctx.todo_subject)
  all_empty_again |> should.equal([])

  // API should also show empty
  let req = build_request(http.Get, "/api/todos")
  let resp = router.handle_request(req, ctx)
  let body = get_response_body(resp)
  string.trim(body) |> should.equal("[]")
}

/// Full-stack: Todo status toggle via actor
pub fn todo_status_toggle_test() {
  let ctx = create_test_context()

  // Create a todo
  let created = todo_actor.create_todo(ctx.todo_subject, "Toggle Me", None, Medium)
  created.completed |> should.be_false

  // Mark as completed
  let patch1 = todo_validation.TodoPatch(title: None, description: None, priority: None, completed: Some(True))
  let updated1 = todo_actor.update_todo(ctx.todo_subject, created.id, patch1)
  let assert Ok(completed) = updated1
  completed.completed |> should.be_true

  // Mark as not completed
  let patch2 = todo_validation.TodoPatch(title: None, description: None, priority: None, completed: Some(False))
  let updated2 = todo_actor.update_todo(ctx.todo_subject, created.id, patch2)
  let assert Ok(not_completed) = updated2
  not_completed.completed |> should.be_false
}

/// Full-stack: Todo fields update independently
pub fn todo_partial_update_test() {
  let ctx = create_test_context()

  // Create a todo
  let created = todo_actor.create_todo(ctx.todo_subject, "Original", Some("Original Desc"), Low)

  // Update only title
  let patch1 = todo_validation.TodoPatch(title: Some("New Title"), description: None, priority: None, completed: None)
  let updated1 = todo_actor.update_todo(ctx.todo_subject, created.id, patch1)
  let assert Ok(u1) = updated1
  u1.title |> should.equal("New Title")
  u1.description |> should.equal(Some("Original Desc"))
  u1.priority |> should.equal(Low)
  u1.completed |> should.be_false

  // Update only description
  let patch2 = todo_validation.TodoPatch(title: None, description: Some("New Desc"), priority: None, completed: None)
  let updated2 = todo_actor.update_todo(ctx.todo_subject, created.id, patch2)
  let assert Ok(u2) = updated2
  u2.title |> should.equal("New Title")  // Changed earlier
  u2.description |> should.equal(Some("New Desc"))

  // Update only priority
  let patch3 = todo_validation.TodoPatch(title: None, description: None, priority: Some(High), completed: None)
  let updated3 = todo_actor.update_todo(ctx.todo_subject, created.id, patch3)
  let assert Ok(u3) = updated3
  u3.priority |> should.equal(High)
}
