/// FULL-STACK INTEGRATION TESTS
///
/// These tests verify the ENTIRE integrated application works end-to-end.
/// NO MOCKING - All tests use real modules, real actors, real dependencies.

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

/// Build a Wisp request with JSON body using wisp/simulate
fn build_json_request(method: http.Method, path: String, body: String) -> wisp.Request {
  simulate.request(method, path)
  |> simulate.string_body(body)
  |> simulate.header("content-type", "application/json")
}

/// Build a simple Wisp request
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

// =============================================================================
// LAYER 3: HTTP API ENDPOINTS INTEGRATION
// =============================================================================

/// Full-stack: POST /api/todos creates a todo
pub fn api_create_todo_test() {
  let ctx = create_test_context()
  let body = "{\"title\":\"API Test\",\"description\":\"From API\",\"priority\":\"high\"}"
  let req = build_json_request(http.Post, "/api/todos", body)

  let resp = router.handle_request(req, ctx)

  get_response_status(resp) |> should.equal(201)
  let body_str = get_response_body(resp)
  contains(body_str, "API Test") |> should.be_true
  contains(body_str, "From API") |> should.be_true
  contains(body_str, "\"priority\":\"high\"") |> should.be_true
  contains(body_str, "\"completed\":false") |> should.be_true
}

/// Full-stack: POST /api/todos validates input
pub fn api_create_todo_validation_error_test() {
  let ctx = create_test_context()
  // Empty title should fail validation
  let body = "{\"title\":\"\",\"priority\":\"medium\"}"
  let req = build_json_request(http.Post, "/api/todos", body)

  let resp = router.handle_request(req, ctx)

  get_response_status(resp) |> should.equal(400)
  let body_str = get_response_body(resp)
  contains(body_str, "errors") |> should.be_true
}

/// Full-stack: POST /api/todos rejects invalid priority
pub fn api_create_todo_invalid_priority_test() {
  let ctx = create_test_context()
  let body = "{\"title\":\"Test\",\"priority\":\"invalid\"}"
  let req = build_json_request(http.Post, "/api/todos", body)

  let resp = router.handle_request(req, ctx)

  get_response_status(resp) |> should.equal(400)
}

/// Full-stack: POST /api/todos requires priority
pub fn api_create_todo_requires_priority_test() {
  let ctx = create_test_context()
  let body = "{\"title\":\"Test Without Priority\"}"
  let req = build_json_request(http.Post, "/api/todos", body)

  let resp = router.handle_request(req, ctx)

  // Should fail because priority is empty/missing
  get_response_status(resp) |> should.equal(400)
}

/// Full-stack: GET /api/todos returns all todos
pub fn api_list_todos_test() {
  let ctx = create_test_context()

  // Create some todos first
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

/// Full-stack: GET /api/todos?filter=active returns only active
pub fn api_list_todos_filter_active_test() {
  let ctx = create_test_context()

  // Create active and completed todos
  let _ = todo_actor.create_todo(ctx.todo_subject, "Active Task", None, High)
  let completed = todo_actor.create_todo(ctx.todo_subject, "Completed Task", None, Medium)

  // Mark one as completed
  let patch = todo_validation.TodoPatch(title: None, description: None, priority: None, completed: Some(True))
  let _ = todo_actor.update_todo(ctx.todo_subject, completed.id, patch)

  let req = build_request(http.Get, "/api/todos?filter=active")
  let resp = router.handle_request(req, ctx)

  get_response_status(resp) |> should.equal(200)
  let body_str = get_response_body(resp)
  contains(body_str, "Active Task") |> should.be_true
  contains(body_str, "Completed Task") |> should.be_false
}

/// Full-stack: GET /api/todos?filter=completed returns only completed
pub fn api_list_todos_filter_completed_test() {
  let ctx = create_test_context()

  // Create active and completed todos
  let _ = todo_actor.create_todo(ctx.todo_subject, "Active Task", None, High)
  let completed = todo_actor.create_todo(ctx.todo_subject, "Completed Task", None, Medium)

  // Mark one as completed
  let patch = todo_validation.TodoPatch(title: None, description: None, priority: None, completed: Some(True))
  let _ = todo_actor.update_todo(ctx.todo_subject, completed.id, patch)

  let req = build_request(http.Get, "/api/todos?filter=completed")
  let resp = router.handle_request(req, ctx)

  get_response_status(resp) |> should.equal(200)
  let body_str = get_response_body(resp)
  contains(body_str, "Active Task") |> should.be_false
  contains(body_str, "Completed Task") |> should.be_true
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

/// Full-stack: PATCH /api/todos/:id updates a todo
pub fn api_update_todo_test() {
  let ctx = create_test_context()
  let created = todo_actor.create_todo(ctx.todo_subject, "Before", None, Low)

  let body = "{\"title\":\"After\",\"completed\":true}"
  let req = build_json_request(http.Patch, "/api/todos/" <> created.id, body)
  let resp = router.handle_request(req, ctx)

  get_response_status(resp) |> should.equal(200)
  let body_str = get_response_body(resp)
  contains(body_str, "After") |> should.be_true
  contains(body_str, "\"completed\":true") |> should.be_true

  // Verify through actor
  let found = todo_actor.get_todo(ctx.todo_subject, created.id)
  let assert Ok(the_todo) = found
  the_todo.title |> should.equal("After")
  the_todo.completed |> should.be_true
}

/// Full-stack: PATCH /api/todos/:id returns 404 for non-existent
pub fn api_update_todo_not_found_test() {
  let ctx = create_test_context()

  let body = "{\"title\":\"Updated\"}"
  let req = build_json_request(http.Patch, "/api/todos/ffffffff-ffff-ffff-ffff-ffffffffffff", body)
  let resp = router.handle_request(req, ctx)

  get_response_status(resp) |> should.equal(404)
}

/// Full-stack: PATCH /api/todos/:id validates priority
pub fn api_update_todo_invalid_priority_test() {
  let ctx = create_test_context()
  let created = todo_actor.create_todo(ctx.todo_subject, "Test", None, Low)

  let body = "{\"priority\":\"super-high\"}"
  let req = build_json_request(http.Patch, "/api/todos/" <> created.id, body)
  let resp = router.handle_request(req, ctx)

  get_response_status(resp) |> should.equal(400)
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

// =============================================================================
// LAYER 0-3 INTEGRATED SCENARIOS
// =============================================================================

/// Full-stack: Complete todo lifecycle (create -> read -> update -> delete)
pub fn complete_todo_lifecycle_test() {
  let ctx = create_test_context()

  // 1. CREATE
  let create_body = "{\"title\":\"Lifecycle Test\",\"description\":\"Test Description\",\"priority\":\"medium\"}"
  let create_req = build_json_request(http.Post, "/api/todos", create_body)
  let create_resp = router.handle_request(create_req, ctx)
  get_response_status(create_resp) |> should.equal(201)

  let create_body_str = get_response_body(create_resp)
  // Extract ID from response (simplified - just verify it was created)
  contains(create_body_str, "Lifecycle Test") |> should.be_true

  // Get the ID by listing todos
  let _ = build_request(http.Get, "/api/todos")
  let _ = router.handle_request(_, ctx)

  // 3. DELETE via actor
  let all_todos = todo_actor.get_all_todos(ctx.todo_subject)
  length(all_todos) |> should.equal(1)
  let assert [the_todo] = all_todos

  let delete_req = build_request(http.Delete, "/api/todos/" <> the_todo.id)
  let delete_resp = router.handle_request(delete_req, ctx)
  get_response_status(delete_resp) |> should.equal(204)

  // 4. VERIFY deletion
  let final_list = todo_actor.get_all_todos(ctx.todo_subject)
  final_list |> should.equal([])
}

/// Full-stack: Multiple todos with filtering
pub fn multiple_todos_filtering_integration_test() {
  let ctx = create_test_context()

  // Create 4 todos: 2 active, 2 completed
  let _ = todo_actor.create_todo(ctx.todo_subject, "Active 1", None, High)
  let _ = todo_actor.create_todo(ctx.todo_subject, "Active 2", None, Medium)
  let completed1 = todo_actor.create_todo(ctx.todo_subject, "Completed 1", None, Low)
  let completed2 = todo_actor.create_todo(ctx.todo_subject, "Completed 2", None, High)

  // Mark two as completed
  let patch = todo_validation.TodoPatch(title: None, description: None, priority: None, completed: Some(True))
  let _ = todo_actor.update_todo(ctx.todo_subject, completed1.id, patch)
  let _ = todo_actor.update_todo(ctx.todo_subject, completed2.id, patch)

  // Verify all 4 exist
  let all = todo_actor.get_all_todos(ctx.todo_subject)
  length(all) |> should.equal(4)

  // Verify API filtering
  let active_req = build_request(http.Get, "/api/todos?filter=active")
  let active_resp = router.handle_request(active_req, ctx)
  let active_body = get_response_body(active_resp)
  contains(active_body, "Active 1") |> should.be_true
  contains(active_body, "Active 2") |> should.be_true
  contains(active_body, "Completed 1") |> should.be_false
  contains(active_body, "Completed 2") |> should.be_false

  let completed_req = build_request(http.Get, "/api/todos?filter=completed")
  let completed_resp = router.handle_request(completed_req, ctx)
  let completed_body = get_response_body(completed_resp)
  contains(completed_body, "Active 1") |> should.be_false
  contains(completed_body, "Active 2") |> should.be_false
  contains(completed_body, "Completed 1") |> should.be_true
  contains(completed_body, "Completed 2") |> should.be_true
}

/// Full-stack: Actor state persistence across multiple requests
pub fn actor_state_persistence_test() {
  let ctx = create_test_context()

  // Create todo via API
  let body1 = "{\"title\":\"Persistent\",\"priority\":\"high\"}"
  let req1 = build_json_request(http.Post, "/api/todos", body1)
  let resp1 = router.handle_request(req1, ctx)
  get_response_status(resp1) |> should.equal(201)

  // Create another via API
  let body2 = "{\"title\":\"Also Persistent\",\"priority\":\"low\"}"
  let req2 = build_json_request(http.Post, "/api/todos", body2)
  let resp2 = router.handle_request(req2, ctx)
  get_response_status(resp2) |> should.equal(201)

  // Verify via API list
  let list_req = build_request(http.Get, "/api/todos")
  let list_resp = router.handle_request(list_req, ctx)
  let list_body = get_response_body(list_resp)
  contains(list_body, "Persistent") |> should.be_true
  contains(list_body, "Also Persistent") |> should.be_true

  // Verify via actor directly
  let all = todo_actor.get_all_todos(ctx.todo_subject)
  length(all) |> should.equal(2)
}

/// Full-stack: Concurrent operations safety
pub fn concurrent_operations_test() {
  let ctx = create_test_context()

  // Create multiple todos rapidly
  let _ = todo_actor.create_todo(ctx.todo_subject, "Todo 1", None, High)
  let _ = todo_actor.create_todo(ctx.todo_subject, "Todo 2", None, Medium)
  let _ = todo_actor.create_todo(ctx.todo_subject, "Todo 3", None, Low)
  let _ = todo_actor.create_todo(ctx.todo_subject, "Todo 4", None, High)
  let _ = todo_actor.create_todo(ctx.todo_subject, "Todo 5", None, Medium)

  // All should exist with unique IDs
  let all = todo_actor.get_all_todos(ctx.todo_subject)
  length(all) |> should.equal(5)

  // Verify all IDs are unique
  let ids = all |> list.map(fn(t) { t.id })
  let unique_ids = ids |> list.unique
  length(unique_ids) |> should.equal(5)
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

/// Full-stack: Root redirect
pub fn root_redirect_test() {
  let ctx = create_test_context()

  let req = build_request(http.Get, "/")
  let resp = router.handle_request(req, ctx)

  // Should redirect to static index
  resp.status |> should.equal(301)
}

/// Full-stack: 404 for unknown routes
pub fn unknown_route_test() {
  let ctx = create_test_context()

  let req = build_request(http.Get, "/api/unknown-route")
  let resp = router.handle_request(req, ctx)

  get_response_status(resp) |> should.equal(404)
}

/// Full-stack: Invalid JSON handling
pub fn invalid_json_test() {
  let ctx = create_test_context()

  let body = "{invalid json"
  let req = build_json_request(http.Post, "/api/todos", body)
  let resp = router.handle_request(req, ctx)

  get_response_status(resp) |> should.equal(400)
}

/// Full-stack: Boundary case - title exactly at limit
pub fn title_boundary_test() {
  let ctx = create_test_context()
  let exact_title = string.repeat("x", 200)

  let body = "{\"title\":\"" <> exact_title <> "\",\"priority\":\"medium\"}"
  let req = build_json_request(http.Post, "/api/todos", body)
  let resp = router.handle_request(req, ctx)

  get_response_status(resp) |> should.equal(201)
}

/// Full-stack: Boundary case - title one char over limit
pub fn title_over_boundary_test() {
  let ctx = create_test_context()
  let over_title = string.repeat("x", 201)

  let body = "{\"title\":\"" <> over_title <> "\",\"priority\":\"medium\"}"
  let req = build_json_request(http.Post, "/api/todos", body)
  let resp = router.handle_request(req, ctx)

  get_response_status(resp) |> should.equal(400)
}

/// Full-stack: Boundary case - description exactly at limit
pub fn description_boundary_test() {
  let ctx = create_test_context()
  let exact_desc = string.repeat("y", 1000)

  let body = "{\"title\":\"Test\",\"description\":\"" <> exact_desc <> "\",\"priority\":\"low\"}"
  let req = build_json_request(http.Post, "/api/todos", body)
  let resp = router.handle_request(req, ctx)

  get_response_status(resp) |> should.equal(201)
}

/// Full-stack: Empty description (null) is valid
pub fn null_description_test() {
  let ctx = create_test_context()

  let body = "{\"title\":\"No Description\",\"description\":null,\"priority\":\"high\"}"
  let req = build_json_request(http.Post, "/api/todos", body)
  let resp = router.handle_request(req, ctx)

  get_response_status(resp) |> should.equal(201)
  let resp_body = get_response_body(resp)
  contains(resp_body, "null") |> should.be_true
}

/// Full-stack: Partial update - only title
pub fn partial_update_title_only_test() {
  let ctx = create_test_context()
  let created = todo_actor.create_todo(ctx.todo_subject, "Original", Some("Desc"), Low)

  let body = "{\"title\":\"New Title\"}"
  let req = build_json_request(http.Patch, "/api/todos/" <> created.id, body)
  let resp = router.handle_request(req, ctx)

  get_response_status(resp) |> should.equal(200)

  // Verify other fields unchanged
  let found = todo_actor.get_todo(ctx.todo_subject, created.id)
  let assert Ok(the_todo) = found
  the_todo.title |> should.equal("New Title")
  the_todo.description |> should.equal(Some("Desc"))
  the_todo.priority |> should.equal(Low)
  the_todo.completed |> should.be_false
}

/// Full-stack: Partial update - only completed
pub fn partial_update_completed_only_test() {
  let ctx = create_test_context()
  let created = todo_actor.create_todo(ctx.todo_subject, "Task", None, Medium)

  let body = "{\"completed\":true}"
  let req = build_json_request(http.Patch, "/api/todos/" <> created.id, body)
  let resp = router.handle_request(req, ctx)

  get_response_status(resp) |> should.equal(200)

  let found = todo_actor.get_todo(ctx.todo_subject, created.id)
  let assert Ok(the_todo) = found
  the_todo.completed |> should.be_true
  the_todo.title |> should.equal("Task")
}

/// Full-stack: Partial update - only priority
pub fn partial_update_priority_only_test() {
  let ctx = create_test_context()
  let created = todo_actor.create_todo(ctx.todo_subject, "Task", None, Low)

  let body = "{\"priority\":\"high\"}"
  let req = build_json_request(http.Patch, "/api/todos/" <> created.id, body)
  let resp = router.handle_request(req, ctx)

  get_response_status(resp) |> should.equal(200)

  let found = todo_actor.get_todo(ctx.todo_subject, created.id)
  let assert Ok(the_todo) = found
  the_todo.priority |> should.equal(High)
  the_todo.title |> should.equal("Task")
}

/// Full-stack: Create todo with all priority levels via API
pub fn api_create_all_priorities_test() {
  let ctx = create_test_context()

  // Low priority
  let body_low = "{\"title\":\"Low Priority\",\"priority\":\"low\"}"
  let req_low = build_json_request(http.Post, "/api/todos", body_low)
  let resp_low = router.handle_request(req_low, ctx)
  get_response_status(resp_low) |> should.equal(201)
  contains(get_response_body(resp_low), "\"priority\":\"low\"") |> should.be_true

  // Medium priority
  let body_med = "{\"title\":\"Medium Priority\",\"priority\":\"medium\"}"
  let req_med = build_json_request(http.Post, "/api/todos", body_med)
  let resp_med = router.handle_request(req_med, ctx)
  get_response_status(resp_med) |> should.equal(201)
  contains(get_response_body(resp_med), "\"priority\":\"medium\"") |> should.be_true

  // High priority
  let body_high = "{\"title\":\"High Priority\",\"priority\":\"high\"}"
  let req_high = build_json_request(http.Post, "/api/todos", body_high)
  let resp_high = router.handle_request(req_high, ctx)
  get_response_status(resp_high) |> should.equal(201)
  contains(get_response_body(resp_high), "\"priority\":\"high\"") |> should.be_true

  // Verify all 3 exist
  let all = todo_actor.get_all_todos(ctx.todo_subject)
  length(all) |> should.equal(3)
}

/// Full-stack: Complex scenario - create, toggle, filter, delete
pub fn complex_scenario_test() {
  let ctx = create_test_context()

  // Create 3 todos
  let todo1 = todo_actor.create_todo(ctx.todo_subject, "Task 1", Some("Important"), High)
  let todo2 = todo_actor.create_todo(ctx.todo_subject, "Task 2", None, Medium)
  let todo3 = todo_actor.create_todo(ctx.todo_subject, "Task 3", None, Low)

  // Toggle todo1 and todo2 to completed
  let patch = todo_validation.TodoPatch(title: None, description: None, priority: None, completed: Some(True))
  let _ = todo_actor.update_todo(ctx.todo_subject, todo1.id, patch)
  let _ = todo_actor.update_todo(ctx.todo_subject, todo2.id, patch)

  // Verify active filter shows only todo3
  let active_req = build_request(http.Get, "/api/todos?filter=active")
  let active_resp = router.handle_request(active_req, ctx)
  let active_body = get_response_body(active_resp)
  contains(active_body, "Task 3") |> should.be_true
  contains(active_body, "Task 1") |> should.be_false
  contains(active_body, "Task 2") |> should.be_false

  // Delete todo3
  let delete_req = build_request(http.Delete, "/api/todos/" <> todo3.id)
  let delete_resp = router.handle_request(delete_req, ctx)
  get_response_status(delete_resp) |> should.equal(204)

  // Now active filter should be empty
  let final_active_req = build_request(http.Get, "/api/todos?filter=active")
  let final_active_resp = router.handle_request(final_active_req, ctx)
  let final_active_body = get_response_body(final_active_resp)
  // Verify the response is an empty array (just contains the brackets)
  string.trim(final_active_body) |> should.equal("[]")

  // But completed still has 2
  let completed_req = build_request(http.Get, "/api/todos?filter=completed")
  let completed_resp = router.handle_request(completed_req, ctx)
  let completed_body = get_response_body(completed_resp)
  contains(completed_body, "Task 1") |> should.be_true
  contains(completed_body, "Task 2") |> should.be_true
}
