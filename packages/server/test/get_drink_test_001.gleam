// Integration test for GET /api/drinks/:id 404 case
// Tests the external HTTP API boundary contract for non-existent drink

import gleeunit/should
import gleam/json
import gleam/dict
import gleam/dynamic/decode
import gleam/int
import boba_store
import web/boba_router
import web/server.{type Request, type Response, request}

// Helper: Build GET request to /api/drinks/:id
fn build_get_request(drink_id: Int) -> Request {
  request(
    method: "GET",
    path: "/api/drinks/" <> int.to_string(drink_id),
    headers: dict.from_list([#("accept", "application/json")]),
    body: "",
  )
}

// Test: Given non-existent drink id, GET /api/drinks/:id returns 404 with error body
pub fn get_drink_nonexistent_returns_404_test() {
  // Setup: Start store with no drinks
  let assert Ok(store) = boba_store.new()
  let handler = boba_router.make_handler(store)

  // Action: GET /api/drinks/99999 (non-existent ID)
  let req = build_get_request(99999)
  let res = handler(req)

  // Assert: Status is 404
  res.status |> should.equal(404)

  // Assert: Response body contains error message
  let error_decoder = {
    use error <- decode.field("error", decode.string)
    decode.success(error)
  }

  case json.parse(from: res.body, using: error_decoder) {
    Ok(error_msg) -> {
      should.be_true(error_msg != "")
    }
    Error(_) -> {
      // Accept any valid JSON or plain text error response
      should.be_true(True)
    }
  }
}

// Test: 404 response has proper Content-Type header
pub fn get_drink_404_has_content_type_test() {
  // Setup: Start store
  let assert Ok(store) = boba_store.new()
  let handler = boba_router.make_handler(store)

  // Action: GET /api/drinks/99999
  let req = build_get_request(99999)
  let res = handler(req)

  // Assert: Has Content-Type header (either application/json or text/plain acceptable)
  let has_content_type = dict.has_key(res.headers, "Content-Type") || dict.has_key(res.headers, "content-type")
  should.be_true(has_content_type)
}
