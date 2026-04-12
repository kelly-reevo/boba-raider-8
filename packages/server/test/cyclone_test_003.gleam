// Integration test: Unsupported Content-Type returns 415
// Tests: Content-Type validation at HTTP boundary

import gleeunit/should
import gleam/json
import gleam/dict
import gleam/option.{None}
import gleam/dynamic/decode
import shared
import todo_store
import web/router
import web/server.{Request}

// Test: POST with text/plain Content-Type returns 415
pub fn post_with_text_plain_content_type_returns_415_test() {
  // Setup: Start store and create handler
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  // Action: POST with unsupported Content-Type
  let req = Request(
    method: "POST",
    path: "/api/todos",
    headers: dict.from_list([#("content-type", "text/plain")]),
    body: "{\"title\": \"test\"}",
  )
  let res = handler(req)

  // Assert: Status is 415
  res.status |> should.equal(415)
}

// Test: POST with application/xml Content-Type returns 415
pub fn post_with_xml_content_type_returns_415_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  // Action: POST with XML Content-Type
  let req = Request(
    method: "POST",
    path: "/api/todos",
    headers: dict.from_list([#("content-type", "application/xml")]),
    body: "<todo><title>test</title></todo>",
  )
  let res = handler(req)

  // Assert: Status is 415
  res.status |> should.equal(415)
}

// Test: POST with form-urlencoded Content-Type returns 415
pub fn post_with_form_urlencoded_returns_415_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  // Action: POST with form data Content-Type
  let req = Request(
    method: "POST",
    path: "/api/todos",
    headers: dict.from_list([#("content-type", "application/x-www-form-urlencoded")]),
    body: "title=test",
  )
  let res = handler(req)

  // Assert: Status is 415
  res.status |> should.equal(415)
}

// Test: PATCH with unsupported Content-Type returns 415
pub fn patch_with_unsupported_content_type_returns_415_test() {
  let assert Ok(store) = todo_store.start()
  let assert Ok(item) = todo_store.create_todo(store, "Test", None, shared.Medium, False)
  let handler = router.make_handler(store)

  // Action: PATCH with text/plain Content-Type
  let req = Request(
    method: "PATCH",
    path: "/api/todos/" <> item.id,
    headers: dict.from_list([#("content-type", "text/html")]),
    body: "some data",
  )
  let res = handler(req)

  // Assert: Status is 415
  res.status |> should.equal(415)
}

// Test: Missing Content-Type on POST returns 415
pub fn post_missing_content_type_returns_415_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  // Action: POST without Content-Type header
  let req = Request(
    method: "POST",
    path: "/api/todos",
    headers: dict.from_list([]),
    body: "{\"title\": \"test\"}",
  )
  let res = handler(req)

  // Assert: Status is 415
  res.status |> should.equal(415)
}

// Test: 415 response includes JSON error body
pub fn content_type_415_response_includes_error_json_test() {
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

  // Assert: Response is valid JSON
  let is_valid_json = case json.parse(from: res.body, using: decode.dynamic) {
    Ok(_) -> True
    Error(_) -> False
  }
  should.be_true(is_valid_json)

  // Assert: Response contains error field
  case json.parse(from: res.body, using: decode.dynamic) {
    Ok(dynamic) -> {
      // Verify it's an object with expected structure
      let decoder = {
        use error <- decode.field("error", decode.string)
        decode.success(error)
      }
      let assert Ok(_) = json.parse(from: res.body, using: decoder)
      should.be_true(True)
    }
    Error(_) -> should.fail()
  }
}
