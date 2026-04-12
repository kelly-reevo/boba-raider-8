// Integration test: PATCH with malformed JSON returns 400 with parse error
// Tests: JSON parsing error handling at HTTP boundary for updates

import gleeunit/should
import gleam/json
import gleam/dict
import gleam/option.{None}
import gleam/string
import gleam/dynamic/decode
import todo_store
import web/router
import web/server.{Request}

// Helper: Create a test todo
fn create_test_todo(store) {
  let assert Ok(item) = todo_store.create_todo(store, "Test", None)
  item
}

// Test: PATCH with invalid JSON syntax returns 400
pub fn patch_malformed_json_returns_400_test() {
  // Setup: Start store and create a todo
  let assert Ok(store) = todo_store.start()
  let existing = create_test_todo(store)
  let handler = router.make_handler(store)

  // Action: PATCH with malformed JSON
  let req = Request(
    method: "PATCH",
    path: "/api/todos/" <> existing.id,
    headers: dict.from_list([#("content-type", "application/json")]),
    body: "{completed: true}",
  )
  let res = handler(req)

  // Assert: Status is 400
  res.status |> should.equal(400)

  // Assert: Response is valid JSON with error field
  let decoder = {
    use error <- decode.field("error", decode.string)
    decode.success(error)
  }
  let assert Ok(error_msg) = json.parse(from: res.body, using: decoder)
  should.be_true(string.length(error_msg) > 0)
}

// Test: PATCH with truncated JSON returns 400
pub fn patch_truncated_json_returns_400_test() {
  let assert Ok(store) = todo_store.start()
  let existing = create_test_todo(store)
  let handler = router.make_handler(store)

  // Action: PATCH with incomplete JSON
  let req = Request(
    method: "PATCH",
    path: "/api/todos/" <> existing.id,
    headers: dict.from_list([#("content-type", "application/json")]),
    body: "{\"title\": \"test\"",
  )
  let res = handler(req)

  // Assert: Status is 400
  res.status |> should.equal(400)
}

// Test: PATCH with empty body returns 400
pub fn patch_empty_body_returns_400_test() {
  let assert Ok(store) = todo_store.start()
  let existing = create_test_todo(store)
  let handler = router.make_handler(store)

  // Action: PATCH with empty body
  let req = Request(
    method: "PATCH",
    path: "/api/todos/" <> existing.id,
    headers: dict.from_list([#("content-type", "application/json")]),
    body: "",
  )
  let res = handler(req)

  // Assert: Status is 400
  res.status |> should.equal(400)
}

// Test: PATCH with non-JSON data returns 400
pub fn patch_non_json_data_returns_400_test() {
  let assert Ok(store) = todo_store.start()
  let existing = create_test_todo(store)
  let handler = router.make_handler(store)

  // Action: PATCH with plain text
  let req = Request(
    method: "PATCH",
    path: "/api/todos/" <> existing.id,
    headers: dict.from_list([#("content-type", "application/json")]),
    body: "not valid json",
  )
  let res = handler(req)

  // Assert: Status is 400
  res.status |> should.equal(400)
}

// Test: PATCH with valid JSON but not an object returns 400
pub fn patch_valid_json_not_object_returns_400_test() {
  let assert Ok(store) = todo_store.start()
  let existing = create_test_todo(store)
  let handler = router.make_handler(store)

  // Action: PATCH with array instead of object
  let req = Request(
    method: "PATCH",
    path: "/api/todos/" <> existing.id,
    headers: dict.from_list([#("content-type", "application/json")]),
    body: "[\"update\", \"values\"]",
  )
  let res = handler(req)

  // Assert: Status is 400
  res.status |> should.equal(400)
}

// Test: PATCH with valid JSON primitive returns 400
pub fn patch_json_primitive_returns_400_test() {
  let assert Ok(store) = todo_store.start()
  let existing = create_test_todo(store)
  let handler = router.make_handler(store)

  // Action: PATCH with string primitive instead of object
  let req = Request(
    method: "PATCH",
    path: "/api/todos/" <> existing.id,
    headers: dict.from_list([#("content-type", "application/json")]),
    body: "\"just a string\"",
  )
  let res = handler(req)

  // Assert: Status is 400
  res.status |> should.equal(400)
}
