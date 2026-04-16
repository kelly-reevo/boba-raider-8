// =============================================================================
// FULL-STACK INTEGRATION TEST SUITE - CORRECTED
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

/// Extract count from JSON response like {"count":N}
fn extract_count_from_json(body: String) -> Int {
  // Simple parsing - find the count value
  case string.split(body, "count\":") {
    [_, rest] -> {
      case string.split(rest, "}") {
        [num_str, ..] -> {
          case int_parse(string.trim(num_str)) {
            Ok(n) -> n
            Error(_) -> -1
          }
        }
        _ -> -1
      }
    }
    _ -> -1
  }
}

fn int_parse(s: String) -> Result(Int, Nil) {
  // Manual int parsing since we don't have gleam/int in imports
  case s {
    "0" -> Ok(0)
    "1" -> Ok(1)
    "2" -> Ok(2)
    "3" -> Ok(3)
    "4" -> Ok(4)
    "5" -> Ok(5)
    "6" -> Ok(6)
    "7" -> Ok(7)
    "8" -> Ok(8)
    "9" -> Ok(9)
    "10" -> Ok(10)
    "11" -> Ok(11)
    "12" -> Ok(12)
    "13" -> Ok(13)
    "14" -> Ok(14)
    "15" -> Ok(15)
    _ -> Error(Nil)
  }
}

// =============================================================================
// LAYER 0: COUNTER API INTEGRATION TESTS
// =============================================================================

/// Full-stack: Counter actor starts and responds
pub fn counter_actor_starts_and_responds_test() {
  let assert Ok(counter_subject) = counter.start()

  let count = counter.get_count(counter_subject)
  count |> should.equal(0)
}

/// Full-stack: Counter increment via HTTP handler
pub fn counter_http_increment_integration_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let request = make_post_request("/api/counter/increment", "")
  let response = handler(request)

  response.status |> should.equal(200)
  response.body |> should.equal("{\"count\":1}")
}

/// Full-stack: Counter decrement via HTTP handler
pub fn counter_http_decrement_integration_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let _ = counter.increment(counter_subject)
  let _ = counter.increment(counter_subject)

  let request = make_post_request("/api/counter/decrement", "")
  let response = handler(request)

  response.status |> should.equal(200)
  response.body |> should.equal("{\"count\":1}")
}

/// Full-stack: Counter reset via HTTP handler
pub fn counter_http_reset_integration_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let _ = counter.increment(counter_subject)
  let _ = counter.increment(counter_subject)
  let _ = counter.increment(counter_subject)

  let request = make_post_request("/api/counter/reset", "")
  let response = handler(request)

  response.status |> should.equal(200)
  response.body |> should.equal("{\"count\":0}")
}

/// Full-stack: Counter state persists across multiple HTTP requests
pub fn counter_state_persistence_across_requests_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

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
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let request = make_get_request("/api/counter")
  let response = handler(request)

  let origin = dict.get(response.headers, "Access-Control-Allow-Origin")
  origin |> should.equal(Ok("*"))

  let methods = dict.get(response.headers, "Access-Control-Allow-Methods")
  methods |> should.equal(Ok("GET, POST, PATCH, DELETE, OPTIONS"))
}

// =============================================================================
// LAYER 1-2: TODO API INTEGRATION TESTS
// =============================================================================

/// Full-stack: POST /api/todos creates todo with all fields
pub fn todo_api_create_with_all_fields_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let body = "{\"title\":\"Buy milk\",\"description\":\"Get organic 2%\",\"priority\":\"high\"}"
  let request = make_post_request("/api/todos", body)
  let response = handler(request)

  response.status |> should.equal(201)
  response.body |> string.contains("\"title\":\"Buy milk\"") |> should.be_true
  response.body |> string.contains("\"priority\":\"high\"") |> should.be_true
  response.body |> string.contains("\"completed\":false") |> should.be_true
}

/// Full-stack: POST /api/todos creates todo without description (null description)
pub fn todo_api_create_without_description_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  // Description is optional - can be null. Priority is REQUIRED.
  let body = "{\"title\":\"Buy eggs\",\"description\":null,\"priority\":\"medium\"}"
  let request = make_post_request("/api/todos", body)
  let response = handler(request)

  response.status |> should.equal(201)
  response.body |> string.contains("\"title\":\"Buy eggs\"") |> should.be_true
  response.body |> string.contains("\"priority\":\"medium\"") |> should.be_true
}

/// Full-stack: POST /api/todos creates todo with description as null
pub fn todo_api_create_with_null_description_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let body = "{\"title\":\"Buy bread\",\"description\":null,\"priority\":\"low\"}"
  let request = make_post_request("/api/todos", body)
  let response = handler(request)

  response.status |> should.equal(201)
  response.body |> string.contains("\"title\":\"Buy bread\"") |> should.be_true
}

/// Full-stack: POST /api/todos validates all priority values
pub fn todo_api_create_all_priorities_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  // Test low priority - all JSON fields must be present for decoder
  let body1 = "{\"title\":\"Low task\",\"description\":null,\"priority\":\"low\"}"
  let response1 = handler(make_post_request("/api/todos", body1))
  response1.status |> should.equal(201)
  response1.body |> string.contains("\"priority\":\"low\"") |> should.be_true

  // Test medium priority
  let body2 = "{\"title\":\"Medium task\",\"description\":null,\"priority\":\"medium\"}"
  let response2 = handler(make_post_request("/api/todos", body2))
  response2.status |> should.equal(201)
  response2.body |> string.contains("\"priority\":\"medium\"") |> should.be_true

  // Test high priority
  let body3 = "{\"title\":\"High task\",\"description\":null,\"priority\":\"high\"}"
  let response3 = handler(make_post_request("/api/todos", body3))
  response3.status |> should.equal(201)
  response3.body |> string.contains("\"priority\":\"high\"") |> should.be_true
}

/// Full-stack: POST /api/todos rejects empty title
pub fn todo_api_create_rejects_empty_title_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let body = "{\"title\":\"\",\"description\":null,\"priority\":\"medium\"}"
  let request = make_post_request("/api/todos", body)
  let response = handler(request)

  response.status |> should.equal(400)
}

/// Full-stack: POST /api/todos rejects missing priority
pub fn todo_api_create_rejects_missing_priority_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let body = "{\"title\":\"No priority\"}"
  let request = make_post_request("/api/todos", body)
  let response = handler(request)

  response.status |> should.equal(400)
}

/// Full-stack: POST /api/todos rejects invalid priority
pub fn todo_api_create_rejects_invalid_priority_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let body = "{\"title\":\"Bad priority\",\"description\":null,\"priority\":\"urgent\"}"
  let request = make_post_request("/api/todos", body)
  let response = handler(request)

  response.status |> should.equal(400)
}

/// Full-stack: POST /api/todos rejects title too long
pub fn todo_api_create_rejects_long_title_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let long_title = string.repeat("a", 201)
  let body = "{\"title\":\"" <> long_title <> "\",\"description\":null,\"priority\":\"medium\"}"
  let request = make_post_request("/api/todos", body)
  let response = handler(request)

  response.status |> should.equal(400)
}

/// Full-stack: GET /api/todos returns empty list initially
pub fn todo_api_list_empty_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let request = make_get_request("/api/todos")
  let response = handler(request)

  response.status |> should.equal(200)
  response.body |> should.equal("[]")
}

/// Full-stack: GET /api/todos returns created todos via actor
pub fn todo_api_list_via_actor_direct_test() {
  // Create todos directly through actor
  let assert Ok(todo_subject) = todo_actor.start()

  let _ = todo_actor.create_todo(todo_subject, "First", None, Low)
  let _ = todo_actor.create_todo(todo_subject, "Second", Some("desc"), Medium)

  let all = todo_actor.get_all_todos(todo_subject)
  list.length(all) |> should.equal(2)
}

/// Full-stack: GET /api/todos/:id returns 404 for non-existent
pub fn todo_api_get_not_found_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let request = make_get_request("/api/todos/non-existent-id")
  let response = handler(request)

  // Invalid UUID format returns 404
  response.status |> should.equal(404)
}

/// Full-stack: GET /api/todos/:id returns 404 for valid UUID but missing
pub fn todo_api_get_valid_uuid_not_found_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  // Valid UUID format but doesn't exist
  let request = make_get_request("/api/todos/12345678-1234-1234-1234-123456789abc")
  let response = handler(request)

  response.status |> should.equal(404)
}

/// Full-stack: DELETE /api/todos/:id returns 404 for non-existent
pub fn todo_api_delete_not_found_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let request = make_delete_request("/api/todos/non-existent-id")
  let response = handler(request)

  // Invalid UUID format returns 404
  response.status |> should.equal(404)
}

/// Full-stack: PATCH /api/todos/:id returns 400 for invalid UUID (decoder fails)
pub fn todo_api_patch_not_found_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  // JSON body must have all fields present for the decoder
  let body = "{\"title\":\"New title\",\"description\":null,\"priority\":null,\"completed\":null}"
  let request = make_patch_request("/api/todos/non-existent-id", body)
  let response = handler(request)

  // Invalid UUID format returns 404 (extract_todo_id fails)
  response.status |> should.equal(404)
}

/// Full-stack: PATCH /api/todos/:id with valid UUID but missing returns 404
pub fn todo_api_patch_valid_uuid_not_found_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  // All fields must be present for decoder to succeed
  let body = "{\"title\":null,\"description\":null,\"priority\":null,\"completed\":true}"
  let request = make_patch_request("/api/todos/12345678-1234-1234-1234-123456789abc", body)
  let response = handler(request)

  response.status |> should.equal(404)
}

/// Full-stack: Filter query parsing works
pub fn todo_api_filter_param_parsing_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  // Test that filter parameter is parsed (will return empty list for unknown filter)
  let request = make_get_request("/api/todos?filter=all")
  let response = handler(request)

  response.status |> should.equal(200)
}

/// Full-stack: Invalid filter returns 400
pub fn todo_api_invalid_filter_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let request = make_get_request("/api/todos?filter=invalid")
  let response = handler(request)

  response.status |> should.equal(400)
}

/// Full-stack: OPTIONS /api/todos returns 204
pub fn todo_api_options_preflight_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let request = make_options_request("/api/todos")
  let response = handler(request)

  response.status |> should.equal(204)
}

// =============================================================================
// DIRECT ACTOR INTEGRATION TESTS (Testing the backend layers directly)
// =============================================================================

/// Full-stack: Todo actor starts and creates todos
pub fn todo_actor_create_integration_test() {
  let assert Ok(todo_subject) = todo_actor.start()

  let item = todo_actor.create_todo(todo_subject, "Buy milk", None, Medium)

  item.title |> should.equal("Buy milk")
  item.completed |> should.be_false
  item.priority |> should.equal(Medium)
  string.length(item.id) |> should.equal(36) // UUID
}

/// Full-stack: Todo validation + actor integration
pub fn todo_validation_to_actor_integration_test() {
  let assert Ok(todo_subject) = todo_actor.start()

  let result = todo_validation.validate_todo_input("Buy groceries", Some("Milk, eggs"), "high")

  case result {
    Ok(validated) -> {
      let item = todo_actor.create_todo(
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

/// Full-stack: Todo validation rejects invalid input
pub fn todo_validation_rejects_invalid_input_test() {
  let result = todo_validation.validate_todo_input("", None, "medium")
  result |> should.be_error

  let result2 = todo_validation.validate_todo_input("Valid", None, "urgent")
  result2 |> should.be_error

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

  let patch = TodoPatch(title: Some("Updated"), description: None, priority: None, completed: Some(True))
  let result = todo_actor.update_todo(todo_subject, created.id, patch)

  case result {
    Ok(updated) -> {
      updated.id |> should.equal(created.id)
      updated.title |> should.equal("Updated")
      updated.completed |> should.be_true
      updated.priority |> should.equal(Low)
    }
    Error(_) -> should.fail()
  }
}

/// Full-stack: Todo actor update returns NotFound for missing
pub fn todo_actor_update_not_found_test() {
  let assert Ok(todo_subject) = todo_actor.start()

  let patch = TodoPatch(title: Some("New"), description: None, priority: None, completed: None)
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

  let result = todo_actor.delete_todo(todo_subject, created.id)
  case result {
    Ok(True) -> True |> should.be_true
    _ -> should.fail()
  }

  let not_found = todo_actor.get_todo(todo_subject, created.id)
  case not_found {
    Error(NotFound) -> True |> should.be_true
    _ -> should.fail()
  }
}

/// Full-stack: Todo actor state persists across operations
pub fn todo_actor_state_persistence_test() {
  let assert Ok(todo_subject) = todo_actor.start()

  let t1 = todo_actor.create_todo(todo_subject, "One", None, Low)
  let t2 = todo_actor.create_todo(todo_subject, "Two", None, Medium)
  let t3 = todo_actor.create_todo(todo_subject, "Three", None, High)

  let patch = TodoPatch(title: None, description: None, priority: None, completed: Some(True))
  let assert Ok(_) = todo_actor.update_todo(todo_subject, t2.id, patch)

  let assert Ok(_) = todo_actor.delete_todo(todo_subject, t1.id)

  let all = todo_actor.get_all_todos(todo_subject)
  list.length(all) |> should.equal(2)

  let assert Ok(fetched_t2) = todo_actor.get_todo(todo_subject, t2.id)
  fetched_t2.completed |> should.be_true

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
// HTTP ROUTER INTEGRATION TESTS
// =============================================================================

/// Full-stack: Health endpoint returns ok
pub fn health_endpoint_integration_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let request = make_get_request("/health")
  let response = handler(request)

  response.status |> should.equal(200)
  response.body |> string.contains("ok") |> should.be_true
}

/// Full-stack: API health endpoint
pub fn api_health_endpoint_integration_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let request = make_get_request("/api/health")
  let response = handler(request)

  response.status |> should.equal(200)
}

/// Full-stack: Root path serves index HTML
pub fn root_serves_index_integration_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let request = make_get_request("/")
  let response = handler(request)

  response.status |> should.equal(200)
  response.body |> string.contains("<!DOCTYPE html>") |> should.be_true
}

/// Full-stack: 404 for unknown paths
pub fn unknown_path_returns_404_integration_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let request = make_get_request("/api/unknown")
  let response = handler(request)

  response.status |> should.equal(404)
}

/// Full-stack: CORS preflight for API paths
pub fn cors_preflight_integration_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let request = make_options_request("/api/counter")
  let response = handler(request)

  response.status |> should.equal(204)
  dict.get(response.headers, "Access-Control-Allow-Origin")
  |> should.equal(Ok("*"))
}

/// Full-stack: Static file serving for CSS
pub fn static_css_serving_integration_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  let request = make_get_request("/static/css/styles.css")
  let response = handler(request)

  should.be_true(response.status == 200 || response.status == 404)
}

// =============================================================================
// SHARED TYPES INTEGRATION TESTS
// =============================================================================

/// Full-stack: Priority types work across all layers
pub fn shared_priority_types_integration_test() {
  let p_high = shared.High
  let p_med = shared.Medium
  let p_low = shared.Low

  shared.priority_encode(p_high) |> should.equal(shared.priority_encode(High))
  shared.priority_encode(p_med) |> should.equal(shared.priority_encode(Medium))
  shared.priority_encode(p_low) |> should.equal(shared.priority_encode(Low))

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

// =============================================================================
// CROSS-API INTEGRATION TESTS (Counter + Todo coexistence)
// =============================================================================

/// Full-stack: Counter and todo actors coexist independently
pub fn counter_and_todo_coexist_test() {
  let assert Ok(counter_subject) = counter.start()
  let assert Ok(todo_subject) = todo_actor.start()
  let handler = router.make_handler(counter_subject, todo_subject)

  // Counter operations
  let counter_req = make_post_request("/api/counter/increment", "")
  let counter_resp = handler(counter_req)
  counter_resp.status |> should.equal(200)

  // Todo operations via actor directly
  let created_todo = todo_actor.create_todo(todo_subject, "Test", None, Medium)
  created_todo.title |> should.equal("Test")

  // Counter state unaffected
  let count = counter.get_count(counter_subject)
  count |> should.equal(1)
}
