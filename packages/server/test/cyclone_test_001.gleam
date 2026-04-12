// Integration test: POST with malformed JSON returns 400 with parse error
// Tests: JSON parsing error handling at HTTP boundary

import gleeunit/should
import gleam/json
import gleam/dict
import gleam/string
import gleam/dynamic/decode
import todo_store
import web/router
import web/server.{Request, Response}

// Test: POST with invalid JSON syntax returns 400
pub fn post_malformed_json_returns_400_test() {
  // Setup: Start store and create handler
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  // Action: POST with malformed JSON (missing quotes, bad syntax)
  let req = Request(
    method: "POST",
    path: "/api/todos",
    headers: dict.from_list([#("content-type", "application/json")]),
    body: "{title: 'no quotes', }",
  )
  let res = handler(req)

  // Assert: Status is 400
  res.status |> should.equal(400)

  // Assert: Response contains error about invalid JSON
  let decoder = {
    use error <- decode.field("error", decode.string)
    decode.success(error)
  }
  let assert Ok(error_msg) = json.parse(from: res.body, using: decoder)
  should.be_true(string.contains(string.lowercase(error_msg), "invalid"))
}

// Test: POST with truncated JSON returns 400
pub fn post_truncated_json_returns_400_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  // Action: POST with incomplete/truncated JSON
  let req = Request(
    method: "POST",
    path: "/api/todos",
    headers: dict.from_list([#("content-type", "application/json")]),
    body: "{\"title\": \"test\"",
  )
  let res = handler(req)

  // Assert: Status is 400
  res.status |> should.equal(400)

  // Assert: Response body is valid JSON
  let is_valid_json = case json.parse(from: res.body, using: decode.dynamic) {
    Ok(_) -> True
    Error(_) -> False
  }
  should.be_true(is_valid_json)
}

// Test: POST with empty body returns 400
pub fn post_empty_body_returns_400_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  // Action: POST with empty body
  let req = Request(
    method: "POST",
    path: "/api/todos",
    headers: dict.from_list([#("content-type", "application/json")]),
    body: "",
  )
  let res = handler(req)

  // Assert: Status is 400
  res.status |> should.equal(400)
}

// Test: POST with non-JSON data type returns 400
pub fn post_non_json_data_returns_400_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  // Action: POST with plain text instead of JSON
  let req = Request(
    method: "POST",
    path: "/api/todos",
    headers: dict.from_list([#("content-type", "application/json")]),
    body: "this is not json",
  )
  let res = handler(req)

  // Assert: Status is 400
  res.status |> should.equal(400)

  // Assert: Error message mentions JSON
  let decoder = {
    use error <- decode.field("error", decode.string)
    decode.success(error)
  }
  let assert Ok(error_msg) = json.parse(from: res.body, using: decoder)
  should.be_true(string.contains(string.lowercase(error_msg), "json"))
}

// Test: POST with valid JSON but wrong structure returns appropriate error
pub fn post_valid_json_wrong_structure_returns_error_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  // Action: POST with valid JSON but not an object
  let req = Request(
    method: "POST",
    path: "/api/todos",
    headers: dict.from_list([#("content-type", "application/json")]),
    body: "[1, 2, 3]",
  )
  let res = handler(req)

  // Assert: Status is 400 (expects object, got array)
  res.status |> should.equal(400)
}

// Test: POST with deeply nested invalid JSON returns 400
pub fn post_deeply_nested_invalid_json_returns_400_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  // Action: POST with unclosed nested structure
  let req = Request(
    method: "POST",
    path: "/api/todos",
    headers: dict.from_list([#("content-type", "application/json")]),
    body: "{\"nested\": {\"unclosed\": \"value\"",
  )
  let res = handler(req)

  // Assert: Status is 400
  res.status |> should.equal(400)
}
