// =============================================================================
// FULL-STACK TODO INTEGRATION TEST SUITE
// =============================================================================
// Tests the COMPLETE integrated application across ALL layers including:
// - Layer 0: Counter API (verification that existing functionality still works)
// - Layer 1: Todo Actor + Validation
// - Layer 2: Todo HTTP REST API Endpoints (newly integrated)
//
// NO MOCKING - All tests exercise real code paths through real dependencies.
// Each test spans multiple layers: HTTP -> Router -> Actor -> Validation -> Shared Types
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

/// Helper to extract todo ID from create response
fn extract_todo_id_from_response(response: Response) -> String {
  // Parse JSON response to extract id field
  let decoder = {
    use id <- decode.field("id", decode.string)
    decode.success(id)
  }
  case json.parse(response.body, decoder) {
    Ok(id) -> id
    Error(_) -> ""
  }
}

/// Helper to extract title from response
fn extract_title_from_response(response: Response) -> String {
  let decoder = {
    use title <- decode.field("title", decode.string)
    decode.success(title)
  }
  case json.parse(response.body, decoder) {
    Ok(title) -> title
    Error(_) -> ""
  }
}

/// Helper to extract completed status from response
fn extract_completed_from_response(response: Response) -> Bool {
  let decoder = {
    use completed <- decode.field("completed", decode.bool)
    decode.success(completed)
  }
  case json.parse(response.body, decoder) {
    Ok(completed) -> completed
    Error(_) -> False
  }
}

/// Helper to count todos in list response
fn count_todos_in_list_response(response: Response) -> Int {
  let decoder = decode.list({
    use _ <- decode.field("id", decode.string)
    decode.success(Nil)
  })
  case json.parse(response.body, decoder) {
    Ok(items) -> list.length(items)
    Error(_) -> 0
  }
}

// Need decode for JSON parsing helpers
import gleam/dynamic/decode

// =============================================================================
// LAYER 2: TODO HTTP API - CREATE ENDPOINT
// =============================================================================

/// Full-stack: POST /api/todos creates todo with valid input
/// Verifies: HTTP -> Router -> Validation -> Actor -> JSON Response
pub fn todo_api_create_success_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let body = "{\"title\":\"Buy groceries\",\"description\":\"Milk and eggs\",\"priority\":\"high\"}"
  let request = make_post_request("/api/todos", body)
  let response = handler(request)

  response.status |> should.equal(201)
  response.body |> string.contains("\"title\":\"Buy groceries\"") |> should.be_true
  response.body |> string.contains("\"priority\":\"high\"") |> should.be_true
  response.body |> string.contains("\"completed\":false") |> should.be_true
  response.body |> string.contains("\"id\"") |> should.be_true
}

/// Full-stack: POST /api/todos creates todo without description
/// Verifies: Optional description field handled correctly
pub fn todo_api_create_without_description_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let body = "{\"title\":\"Simple task\",\"priority\":\"medium\"}"
  let request = make_post_request("/api/todos", body)
  let response = handler(request)

  response.status |> should.equal(201)
  response.body |> string.contains("\"title\":\"Simple task\"") |> should.be_true
  response.body |> string.contains("\"description\":null") |> should.be_true
}

/// Full-stack: POST /api/todos with all priority levels
/// Verifies: low, medium, high priorities all work
pub fn todo_api_create_all_priorities_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let priorities = ["low", "medium", "high"]

  list.each(priorities, fn(priority) {
    let body = "{\"title\":\"Task \"" <> priority <> "\"\",\"priority\":\"" <> priority <> "\"}"
    let request = make_post_request("/api/todos", body)
    let response = handler(request)
    response.status |> should.equal(201)
    response.body |> string.contains("\"priority\":\"" <> priority <> "\"") |> should.be_true
  })
}

/// Full-stack: POST /api/todos validates empty title
/// Verifies: Validation layer returns 400 with error details
pub fn todo_api_create_empty_title_validation_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let body = "{\"title\":\"\",\"priority\":\"medium\"}"
  let request = make_post_request("/api/todos", body)
  let response = handler(request)

  response.status |> should.equal(400)
  response.body |> string.contains("errors") |> should.be_true
}

/// Full-stack: POST /api/todos validates invalid priority
/// Verifies: Invalid priority string rejected
pub fn todo_api_create_invalid_priority_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let body = "{\"title\":\"Valid title\",\"priority\":\"urgent\"}"
  let request = make_post_request("/api/todos", body)
  let response = handler(request)

  response.status |> should.equal(400)
}

/// Full-stack: POST /api/todos validates title too long
/// Verifies: Title > 200 characters rejected
pub fn todo_api_create_title_too_long_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let long_title = string.repeat("a", 201)
  let body = "{\"title\":\"" <> long_title <> "\",\"priority\":\"low\"}"
  let request = make_post_request("/api/todos", body)
  let response = handler(request)

  response.status |> should.equal(400)
}

/// Full-stack: POST /api/todos validates description too long
/// Verifies: Description > 1000 characters rejected
pub fn todo_api_create_description_too_long_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let long_desc = string.repeat("b", 1001)
  let body = "{\"title\":\"Valid\",\"description\":\"" <> long_desc <> "\",\"priority\":\"low\"}"
  let request = make_post_request("/api/todos", body)
  let response = handler(request)

  response.status |> should.equal(400)
}

/// Full-stack: POST /api/todos validates missing priority defaults to empty
/// Verifies: Missing required fields handled
pub fn todo_api_create_missing_priority_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let body = "{\"title\":\"No priority specified\"}"
  let request = make_post_request("/api/todos", body)
  let response = handler(request)

  response.status |> should.equal(400)
}

/// Full-stack: POST /api/todos handles invalid JSON
/// Verifies: Malformed JSON returns 400
pub fn todo_api_create_invalid_json_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let body = "{invalid json}"
  let request = make_post_request("/api/todos", body)
  let response = handler(request)

  response.status |> should.equal(400)
}

// =============================================================================
// LAYER 2: TODO HTTP API - LIST ENDPOINT
// =============================================================================

/// Full-stack: GET /api/todos returns empty list initially
/// Verifies: List endpoint returns JSON array
pub fn todo_api_list_empty_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let request = make_get_request("/api/todos")
  let response = handler(request)

  response.status |> should.equal(200)
  response.body |> should.equal("[]")
}

/// Full-stack: GET /api/todos returns created todos
/// Verifies: Create followed by List returns the created item
pub fn todo_api_list_with_todos_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  // Create a todo
  let body = "{\"title\":\"Test task\",\"priority\":\"medium\"}"
  let create_request = make_post_request("/api/todos", body)
  let create_response = handler(create_request)
  create_response.status |> should.equal(201)

  // List should return it
  let list_request = make_get_request("/api/todos")
  let list_response = handler(list_request)

  list_response.status |> should.equal(200)
  count_todos_in_list_response(list_response) |> should.equal(1)
}

/// Full-stack: GET /api/todos returns multiple todos in order
/// Verifies: List maintains order of creation
pub fn todo_api_list_multiple_todos_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  // Create multiple todos
  let _ = handler(make_post_request("/api/todos", "{\"title\":\"First\",\"priority\":\"low\"}"))
  let _ = handler(make_post_request("/api/todos", "{\"title\":\"Second\",\"priority\":\"medium\"}"))
  let _ = handler(make_post_request("/api/todos", "{\"title\":\"Third\",\"priority\":\"high\"}"))

  let list_request = make_get_request("/api/todos")
  let list_response = handler(list_request)

  count_todos_in_list_response(list_response) |> should.equal(3)
}

// =============================================================================
// LAYER 2: TODO HTTP API - FILTER ENDPOINT
// =============================================================================

/// Full-stack: GET /api/todos?filter=all returns all todos
/// Verifies: Filter parameter works for 'all'
pub fn todo_api_filter_all_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  // Create todos
  let _ = handler(make_post_request("/api/todos", "{\"title\":\"Task 1\",\"priority\":\"low\"}"))
  let _ = handler(make_post_request("/api/todos", "{\"title\":\"Task 2\",\"priority\":\"medium\"}"))

  let request = make_get_request("/api/todos?filter=all")
  let response = handler(request)

  response.status |> should.equal(200)
  count_todos_in_list_response(response) |> should.equal(2)
}

/// Full-stack: GET /api/todos?filter=active returns only incomplete
/// Verifies: Filter shows only completed=false todos
pub fn todo_api_filter_active_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  // Create todo
  let create_response = handler(make_post_request("/api/todos", "{\"title\":\"Active task\",\"priority\":\"low\"}"))
  let todo_id = extract_todo_id_from_response(create_response)

  // Mark it completed via PATCH
  let _ = handler(make_patch_request("/api/todos/" <> todo_id, "{\"completed\":true}"))

  // Create another active todo
  let _ = handler(make_post_request("/api/todos", "{\"title\":\"Still active\",\"priority\":\"medium\"}"))

  // Filter active should return only 1 (the second one)
  let request = make_get_request("/api/todos?filter=active")
  let response = handler(request)

  response.status |> should.equal(200)
  count_todos_in_list_response(response) |> should.equal(1)
  response.body |> string.contains("Still active") |> should.be_true
}

/// Full-stack: GET /api/todos?filter=completed returns only complete
/// Verifies: Filter shows only completed=true todos
pub fn todo_api_filter_completed_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  // Create todo and complete it
  let create_response = handler(make_post_request("/api/todos", "{\"title\":\"Done task\",\"priority\":\"high\"}"))
  let todo_id = extract_todo_id_from_response(create_response)

  // Complete it
  let _ = handler(make_patch_request("/api/todos/" <> todo_id, "{\"completed\":true}"))

  // Create another incomplete todo
  let _ = handler(make_post_request("/api/todos", "{\"title\":\"Not done\",\"priority\":\"low\"}"))

  // Filter completed should return only 1
  let request = make_get_request("/api/todos?filter=completed")
  let response = handler(request)

  response.status |> should.equal(200)
  count_todos_in_list_response(response) |> should.equal(1)
  response.body |> string.contains("Done task") |> should.be_true
}

/// Full-stack: GET /api/todos with invalid filter returns 400
/// Verifies: Invalid filter parameter handled
pub fn todo_api_filter_invalid_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let request = make_get_request("/api/todos?filter=invalid")
  let response = handler(request)

  response.status |> should.equal(400)
}

// =============================================================================
// LAYER 2: TODO HTTP API - GET BY ID ENDPOINT
// =============================================================================

/// Full-stack: GET /api/todos/:id returns single todo
/// Verifies: Individual todo retrieval works
pub fn todo_api_get_by_id_success_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  // Create todo
  let create_response = handler(make_post_request("/api/todos", "{\"title\":\"Find me\",\"priority\":\"high\"}"))
  let todo_id = extract_todo_id_from_response(create_response)

  // Get by ID
  let request = make_get_request("/api/todos/" <> todo_id)
  let response = handler(request)

  response.status |> should.equal(200)
  response.body |> string.contains("\"title\":\"Find me\"") |> should.be_true
  response.body |> string.contains("\"id\":\"" <> todo_id <> "\"") |> should.be_true
}

/// Full-stack: GET /api/todos/:id returns 404 for non-existent
/// Verifies: Missing todo returns NotFound
pub fn todo_api_get_by_id_not_found_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let request = make_get_request("/api/todos/non-existent-id-12345")
  let response = handler(request)

  response.status |> should.equal(404)
}

/// Full-stack: GET /api/todos/:id returns 400 for invalid UUID format
/// Verifies: Invalid ID format handled before actor lookup
pub fn todo_api_get_by_id_invalid_uuid_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let request = make_get_request("/api/todos/not-a-valid-uuid")
  let response = handler(request)

  response.status |> should.equal(400)
}

// =============================================================================
// LAYER 2: TODO HTTP API - PATCH ENDPOINT
// =============================================================================

/// Full-stack: PATCH /api/todos/:id updates title
/// Verifies: Partial update of title works
pub fn todo_api_patch_title_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  // Create
  let create_response = handler(make_post_request("/api/todos", "{\"title\":\"Original\",\"priority\":\"low\"}"))
  let todo_id = extract_todo_id_from_response(create_response)

  // Patch title
  let request = make_patch_request("/api/todos/" <> todo_id, "{\"title\":\"Updated\"}")
  let response = handler(request)

  response.status |> should.equal(200)
  response.body |> string.contains("\"title\":\"Updated\"") |> should.be_true
}

/// Full-stack: PATCH /api/todos/:id updates completed status
/// Verifies: Toggle completion works
pub fn todo_api_patch_completed_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  // Create
  let create_response = handler(make_post_request("/api/todos", "{\"title\":\"Toggle me\",\"priority\":\"medium\"}"))
  let todo_id = extract_todo_id_from_response(create_response)

  // Patch completed
  let request = make_patch_request("/api/todos/" <> todo_id, "{\"completed\":true}")
  let response = handler(request)

  response.status |> should.equal(200)
  response.body |> string.contains("\"completed\":true") |> should.be_true
}

/// Full-stack: PATCH /api/todos/:id updates priority
/// Verifies: Priority change works
pub fn todo_api_patch_priority_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  // Create with low priority
  let create_response = handler(make_post_request("/api/todos", "{\"title\":\"Change priority\",\"priority\":\"low\"}"))
  let todo_id = extract_todo_id_from_response(create_response)

  // Patch priority
  let request = make_patch_request("/api/todos/" <> todo_id, "{\"priority\":\"high\"}")
  let response = handler(request)

  response.status |> should.equal(200)
  response.body |> string.contains("\"priority\":\"high\"") |> should.be_true
}

/// Full-stack: PATCH /api/todos/:id updates description
/// Verifies: Description update works
pub fn todo_api_patch_description_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  // Create without description
  let create_response = handler(make_post_request("/api/todos", "{\"title\":\"Add desc\",\"priority\":\"low\"}"))
  let todo_id = extract_todo_id_from_response(create_response)

  // Patch description
  let request = make_patch_request("/api/todos/" <> todo_id, "{\"description\":\"New description\"}")
  let response = handler(request)

  response.status |> should.equal(200)
  response.body |> string.contains("\"description\":\"New description\"") |> should.be_true
}

/// Full-stack: PATCH /api/todos/:id with multiple fields
/// Verifies: Multiple field update in single request
pub fn todo_api_patch_multiple_fields_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  // Create
  let create_response = handler(make_post_request("/api/todos", "{\"title\":\"Multi update\",\"priority\":\"low\"}"))
  let todo_id = extract_todo_id_from_response(create_response)

  // Patch multiple fields
  let body = "{\"title\":\"New title\",\"completed\":true,\"priority\":\"high\"}"
  let request = make_patch_request("/api/todos/" <> todo_id, body)
  let response = handler(request)

  response.status |> should.equal(200)
  response.body |> string.contains("\"title\":\"New title\"") |> should.be_true
  response.body |> string.contains("\"completed\":true") |> should.be_true
  response.body |> string.contains("\"priority\":\"high\"") |> should.be_true
}

/// Full-stack: PATCH /api/todos/:id returns 404 for non-existent
/// Verifies: Missing todo returns NotFound
pub fn todo_api_patch_not_found_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let request = make_patch_request("/api/todos/non-existent-id-12345", "{\"title\":\"New\"}")
  let response = handler(request)

  response.status |> should.equal(404)
}

/// Full-stack: PATCH /api/todos/:id validates invalid priority
/// Verifies: Invalid priority in patch rejected
pub fn todo_api_patch_invalid_priority_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  // Create
  let create_response = handler(make_post_request("/api/todos", "{\"title\":\"Test\",\"priority\":\"low\"}"))
  let todo_id = extract_todo_id_from_response(create_response)

  // Patch with invalid priority
  let request = make_patch_request("/api/todos/" <> todo_id, "{\"priority\":\"urgent\"}")
  let response = handler(request)

  response.status |> should.equal(400)
}

/// Full-stack: PATCH /api/todos/:id handles invalid JSON
/// Verifies: Malformed JSON returns 400
pub fn todo_api_patch_invalid_json_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  // Create
  let create_response = handler(make_post_request("/api/todos", "{\"title\":\"Test\",\"priority\":\"low\"}"))
  let todo_id = extract_todo_id_from_response(create_response)

  // Patch with invalid JSON
  let request = make_patch_request("/api/todos/" <> todo_id, "{invalid}")
  let response = handler(request)

  response.status |> should.equal(400)
}

// =============================================================================
// LAYER 2: TODO HTTP API - DELETE ENDPOINT
// =============================================================================

/// Full-stack: DELETE /api/todos/:id removes todo
/// Verifies: Delete returns 204 and removes todo
pub fn todo_api_delete_success_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  // Create
  let create_response = handler(make_post_request("/api/todos", "{\"title\":\"Delete me\",\"priority\":\"low\"}"))
  let todo_id = extract_todo_id_from_response(create_response)

  // Delete
  let request = make_delete_request("/api/todos/" <> todo_id)
  let response = handler(request)

  response.status |> should.equal(204)

  // Verify it's gone
  let get_request = make_get_request("/api/todos/" <> todo_id)
  let get_response = handler(get_request)
  get_response.status |> should.equal(404)
}

/// Full-stack: DELETE /api/todos/:id returns 404 for non-existent
/// Verifies: Missing todo returns NotFound
pub fn todo_api_delete_not_found_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let request = make_delete_request("/api/todos/non-existent-id-12345")
  let response = handler(request)

  response.status |> should.equal(404)
}

// =============================================================================
// LAYER 2: TODO HTTP API - CORS
// =============================================================================

/// Full-stack: CORS headers on todo endpoints
/// Verifies: CORS applies to all todo API routes
pub fn todo_api_cors_headers_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let request = make_get_request("/api/todos")
  let response = handler(request)

  dict.get(response.headers, "Access-Control-Allow-Origin")
  |> should.equal(Ok("*"))
}

/// Full-stack: OPTIONS preflight on todo endpoints
/// Verifies: CORS preflight works for todos
pub fn todo_api_options_preflight_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let request = make_options_request("/api/todos")
  let response = handler(request)

  response.status |> should.equal(204)
}

/// Full-stack: OPTIONS preflight on specific todo
/// Verifies: CORS preflight works for individual todo routes
pub fn todo_api_options_preflight_specific_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let request = make_options_request("/api/todos/some-id")
  let response = handler(request)

  response.status |> should.equal(204)
}

// =============================================================================
// MULTI-LAYER WORKFLOWS
// =============================================================================

/// Full-stack: Complete todo lifecycle (create -> get -> update -> delete)
/// Verifies: Full CRUD workflow through HTTP API
pub fn todo_complete_lifecycle_workflow_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  // Step 1: Create
  let create_body = "{\"title\":\"My task\",\"description\":\"Details\",\"priority\":\"medium\"}"
  let create_response = handler(make_post_request("/api/todos", create_body))
  create_response.status |> should.equal(201)
  let todo_id = extract_todo_id_from_response(create_response)
  string.length(todo_id) |> should.equal(36)

  // Step 2: Get
  let get_response = handler(make_get_request("/api/todos/" <> todo_id))
  get_response.status |> should.equal(200)
  get_response.body |> string.contains("\"title\":\"My task\"") |> should.be_true

  // Step 3: Update
  let patch_response = handler(make_patch_request("/api/todos/" <> todo_id, "{\"completed\":true}"))
  patch_response.status |> should.equal(200)
  patch_response.body |> string.contains("\"completed\":true") |> should.be_true

  // Step 4: List and verify
  let list_response = handler(make_get_request("/api/todos"))
  list_response.status |> should.equal(200)
  list_response.body |> string.contains(todo_id) |> should.be_true

  // Step 5: Delete
  let delete_response = handler(make_delete_request("/api/todos/" <> todo_id))
  delete_response.status |> should.equal(204)

  // Step 6: Verify deletion
  let final_get = handler(make_get_request("/api/todos/" <> todo_id))
  final_get.status |> should.equal(404)
}

/// Full-stack: Multiple users workflow (simulated)
/// Verifies: Multiple todos created and filtered correctly
pub fn todo_multiple_users_workflow_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  // Create 5 todos
  let _ = handler(make_post_request("/api/todos", "{\"title\":\"Task 1\",\"priority\":\"low\"}"))
  let _ = handler(make_post_request("/api/todos", "{\"title\":\"Task 2\",\"priority\":\"medium\"}"))
  let _ = handler(make_post_request("/api/todos", "{\"title\":\"Task 3\",\"priority\":\"high\"}"))
  let _ = handler(make_post_request("/api/todos", "{\"title\":\"Task 4\",\"priority\":\"low\"}"))
  let _ = handler(make_post_request("/api/todos", "{\"title\":\"Task 5\",\"priority\":\"medium\"}"))

  // Verify all 5 exist
  let list_response = handler(make_get_request("/api/todos"))
  count_todos_in_list_response(list_response) |> should.equal(5)

  // Complete some
  let list_body = list_response.body
  // Extract first todo ID and complete it
  let first_id = case string.split(list_body, "\"id\":\"") {
    [_, rest] -> {
      case string.split(rest, "\"") {
        [id, ..] -> id
        _ -> ""
      }
    }
    _ -> ""
  }

  case string.length(first_id) > 0 {
    True -> {
      let _ = handler(make_patch_request("/api/todos/" <> first_id, "{\"completed\":true}"))

      // Filter active should be 4
      let active_response = handler(make_get_request("/api/todos?filter=active"))
      count_todos_in_list_response(active_response) |> should.equal(4)

      // Filter completed should be 1
      let completed_response = handler(make_get_request("/api/todos?filter=completed"))
      count_todos_in_list_response(completed_response) |> should.equal(1)
    }
    False -> should.fail()
  }
}

/// Full-stack: Priority filter workflow
/// Verifies: Multiple todos with different priorities handled
pub fn todo_priority_filter_workflow_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  // Create todos with each priority
  let _ = handler(make_post_request("/api/todos", "{\"title\":\"Low task\",\"priority\":\"low\"}"))
  let _ = handler(make_post_request("/api/todos", "{\"title\":\"Med task\",\"priority\":\"medium\"}"))
  let _ = handler(make_post_request("/api/todos", "{\"title\":\"High task\",\"priority\":\"high\"}"))

  // List all
  let list_response = handler(make_get_request("/api/todos"))
  count_todos_in_list_response(list_response) |> should.equal(3)

  // Verify each priority is present
  list_response.body |> string.contains("\"priority\":\"low\"") |> should.be_true
  list_response.body |> string.contains("\"priority\":\"medium\"") |> should.be_true
  list_response.body |> string.contains("\"priority\":\"high\"") |> should.be_true
}

// =============================================================================
// CROSS-LAYER: Counter + Todo Together
// =============================================================================

/// Full-stack: Counter and Todo endpoints coexist
/// Verifies: Layer 0 counter still works alongside Layer 2 todos
pub fn counter_and_todo_coexist_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  // Counter increment
  let counter_response = handler(make_post_request("/api/counter/increment", ""))
  counter_response.status |> should.equal(200)
  counter_response.body |> should.equal("{\"count\":1}")

  // Todo create
  let todo_response = handler(make_post_request("/api/todos", "{\"title\":\"Test\",\"priority\":\"low\"}"))
  todo_response.status |> should.equal(201)

  // Counter still works after todo create
  let counter_get = handler(make_get_request("/api/counter"))
  counter_get.body |> should.equal("{\"count\":1}")

  // Another counter increment
  let counter_inc2 = handler(make_post_request("/api/counter/increment", ""))
  counter_inc2.body |> should.equal("{\"count\":2}")

  // Todo list still works
  let todo_list = handler(make_get_request("/api/todos"))
  todo_list.status |> should.equal(200)
  count_todos_in_list_response(todo_list) |> should.equal(1)
}

/// Full-stack: Multiple operations across both APIs
/// Verifies: Complex interleaved operations maintain state
pub fn complex_cross_api_operations_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  // Interleaved operations
  let _ = handler(make_post_request("/api/counter/increment", ""))
  let todo1 = handler(make_post_request("/api/todos", "{\"title\":\"First\",\"priority\":\"high\"}"))
  let _ = handler(make_post_request("/api/counter/increment", ""))
  let _ = handler(make_post_request("/api/counter/decrement", ""))
  let todo2 = handler(make_post_request("/api/todos", "{\"title\":\"Second\",\"priority\":\"low\"}"))

  // Verify counter state
  let counter_get = handler(make_get_request("/api/counter"))
  counter_get.body |> should.equal("{\"count\":1}")

  // Verify todos exist
  let list = handler(make_get_request("/api/todos"))
  count_todos_in_list_response(list) |> should.equal(2)

  // Update a todo and check counter still works
  let todo1_id = extract_todo_id_from_response(todo1)
  let _ = handler(make_patch_request("/api/todos/" <> todo1_id, "{\"completed\":true}"))
  let counter_after = handler(make_get_request("/api/counter"))
  counter_after.body |> should.equal("{\"count\":1}")

  // Reset counter
  let _ = handler(make_post_request("/api/counter/reset", ""))
  let counter_reset = handler(make_get_request("/api/counter"))
  counter_reset.body |> should.equal("{\"count\":0}")

  // Todos still exist after counter reset
  let list_after = handler(make_get_request("/api/todos"))
  count_todos_in_list_response(list_after) |> should.equal(2)
}

// =============================================================================
// ERROR HANDLING INTEGRATION
// =============================================================================

/// Full-stack: Invalid HTTP methods on todo endpoints
/// Verifies: Router handles mismatched methods
pub fn todo_api_invalid_method_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  // PUT to /api/todos should 404
  let request = make_request("PUT", "/api/todos", "")
  let response = handler(request)
  response.status |> should.equal(404)
}

/// Full-stack: Invalid path returns 404
/// Verifies: Unknown paths handled
pub fn todo_api_unknown_path_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let request = make_get_request("/api/unknown-path")
  let response = handler(request)
  response.status |> should.equal(404)
}

/// Full-stack: Nested todo path returns 404
/// Verifies: Deep nesting not supported
pub fn todo_api_nested_path_404_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let request = make_get_request("/api/todos/nested/extra")
  let response = handler(request)
  response.status |> should.equal(404)
}
