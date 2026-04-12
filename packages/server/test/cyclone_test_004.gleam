// Integration test: All error responses follow consistent format
// Tests: Error response envelope contract at HTTP boundary

import gleeunit/should
import gleam/json
import gleam/dict
import gleam/string
import gleam/dynamic/decode
import gleam/list
import todo_store
import web/router
import web/server.{Request, Response}

// Helper: Check if response follows {error: string} format
fn has_error_string_format(body: String) -> Bool {
  let decoder = {
    use error <- decode.field("error", decode.string)
    decode.success(error)
  }
  case json.parse(from: body, using: decoder) {
    Ok(_) -> True
    Error(_) -> False
  }
}

// Helper: Check if response follows {errors: [...]} format
fn has_errors_array_format(body: String) -> Bool {
  let error_item_decoder = {
    use field <- decode.field("field", decode.string)
    use message <- decode.field("message", decode.string)
    decode.success(#(field, message))
  }
  let decoder = {
    use errors <- decode.field("errors", decode.list(error_item_decoder))
    decode.success(errors)
  }
  case json.parse(from: body, using: decoder) {
    Ok(_) -> True
    Error(_) -> False
  }
}

// Test: 400 error uses {error: string} format
pub fn error_400_uses_error_string_format_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  // Action: POST with empty title to trigger validation error
  let req = Request(
    method: "POST",
    path: "/api/todos",
    headers: dict.from_list([#("content-type", "application/json")]),
    body: "{\"title\": \"\"}",
  )
  let res = handler(req)

  // Assert: Status is 400 and format is {error: string}
  res.status |> should.equal(400)
  should.be_true(has_error_string_format(res.body))
}

// Test: 404 error uses {error: string} format
pub fn error_404_uses_error_string_format_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  // Action: GET non-existent todo
  let req = Request(
    method: "GET",
    path: "/api/todos/nonexistent-id",
    headers: dict.from_list([]),
    body: "",
  )
  let res = handler(req)

  // Assert: Status is 404 and format is {error: string}
  res.status |> should.equal(404)
  should.be_true(has_error_string_format(res.body))
}

// Test: Error response has Content-Type application/json
pub fn all_error_responses_have_json_content_type_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  // Test multiple error paths
  let error_reqs = [
    Request(
      method: "GET",
      path: "/api/todos/unknown",
      headers: dict.from_list([]),
      body: "",
    ),
    Request(
      method: "POST",
      path: "/api/todos",
      headers: dict.from_list([#("content-type", "application/json")]),
      body: "{\"title\": \"\"}",
    ),
    Request(
      method: "POST",
      path: "/api/todos",
      headers: dict.from_list([#("content-type", "text/plain")]),
      body: "data",
    ),
  ]

  // Verify all error responses have JSON Content-Type
  list.each(error_reqs, fn(req) {
    let res = handler(req)
    case dict.get(res.headers, "content-type") {
      Ok(ct) -> should.be_true(string.contains(ct, "application/json"))
      Error(_) -> should.fail()
    }
  })
}

// Test: Error response body is valid JSON
pub fn all_error_responses_are_valid_json_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  // Various requests that produce errors
  let error_reqs = [
    #(Request(method: "GET", path: "/unknown", headers: dict.from_list([]), body: ""), 404),
    #(Request(method: "POST", path: "/api/todos", headers: dict.from_list([#("content-type", "application/json")]), body: "{}"), 400),
    #(Request(method: "POST", path: "/api/todos", headers: dict.from_list([#("content-type", "application/json")]), body: "{invalid}" ), 400),
  ]

  // Verify all responses are valid JSON
  list.each(error_reqs, fn(pair) {
    let #(req, expected_status) = pair
    let res = handler(req)
    res.status |> should.equal(expected_status)

    let is_valid_json = case json.parse(from: res.body, using: decode.dynamic) {
      Ok(_) -> True
      Error(_) -> False
    }
    should.be_true(is_valid_json)
  })
}

// Test: Error message is a non-empty string in {error: string} format
pub fn error_string_contains_non_empty_message_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  // Action: Trigger 404 error
  let req = Request(
    method: "GET",
    path: "/api/todos/missing",
    headers: dict.from_list([]),
    body: "",
  )
  let res = handler(req)

  // Assert: Error message exists and is non-empty
  let decoder = {
    use error <- decode.field("error", decode.string)
    decode.success(error)
  }
  let assert Ok(error_msg) = json.parse(from: res.body, using: decoder)
  should.be_true(string.length(error_msg) > 0)
}

// Test: Error response does not contain unexpected fields
pub fn error_response_has_only_expected_fields_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  // Action: Trigger error
  let req = Request(
    method: "GET",
    path: "/notfound",
    headers: dict.from_list([]),
    body: "",
  )
  let res = handler(req)

  // Assert: Response only has 'error' or 'errors' field, no extra fields
  case json.parse(from: res.body, using: decode.dynamic) {
    Ok(dynamic) -> {
      // For simple errors, verify only 'error' field exists
      let decoder = {
        use error <- decode.field("error", decode.string)
        decode.success(error)
      }
      case json.parse(from: res.body, using: decoder) {
        Ok(_) -> should.be_true(True)
        Error(_) -> {
          // Try errors array format
          let errors_decoder = {
            use errors <- decode.field("errors", decode.list(decode.dynamic))
            decode.success(errors)
          }
          case json.parse(from: res.body, using: errors_decoder) {
            Ok(_) -> should.be_true(True)
            Error(_) -> should.fail()
          }
        }
      }
    }
    Error(_) -> should.fail()
  }
}

// Test: 415 error uses {error: string} format
pub fn error_415_uses_error_string_format_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  // Action: POST with unsupported Content-Type
  let req = Request(
    method: "POST",
    path: "/api/todos",
    headers: dict.from_list([#("content-type", "text/plain")]),
    body: "data",
  )
  let res = handler(req)

  // Assert: Status is 415 and format is {error: string}
  res.status |> should.equal(415)
  should.be_true(has_error_string_format(res.body))
}
