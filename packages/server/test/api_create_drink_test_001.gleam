// Integration test for POST /api/drinks endpoint - invalid store_id
// Tests the external HTTP API boundary contract for store not found error

import gleeunit/should
import gleam/json
import gleam/dict
import gleam/string
import gleam/dynamic/decode
import boba_store
import web/boba_router
import web/server.{type Request, request}

// Helper: Build a POST request to /api/drinks with JSON body
fn build_post_request(body: String) -> Request {
  request(
    method: "POST",
    path: "/api/drinks",
    headers: dict.from_list([
      #("accept", "application/json"),
      #("content-type", "application/json"),
    ]),
    body: body,
  )
}

// Helper: Decode error response JSON
fn decode_error_response(json_string: String) -> String {
  let decoder = {
    use error <- decode.field("error", decode.string)
    decode.success(error)
  }

  case json.parse(from: json_string, using: decoder) {
    Ok(msg) -> msg
    Error(_) -> "Unknown error"
  }
}

// Helper: Decode error message field
fn decode_error_message_response(json_string: String) -> String {
  let decoder = {
    use msg <- decode.field("message", decode.string)
    decode.success(msg)
  }

  case json.parse(from: json_string, using: decoder) {
    Ok(msg) -> msg
    Error(_) -> "Unknown error"
  }
}

// Test: Given invalid store_id, when POST /api/drinks, then returns 404 'store not found'
// Test type: integration (tests HTTP API boundary contract for error case)
// Acceptance criterion: Given invalid store_id, then returns 404 'store not found'
pub fn create_drink_invalid_store_id_returns_404_test() {
  // Setup: Start store (no stores created, so any store_id is invalid)
  let assert Ok(store) = boba_store.new()
  let handler = boba_router.make_handler(store)

  // Build drink payload with invalid/non-existent store_id
  let payload = json.to_string(json.object([
    #("store_id", json.int(999999)),
    #("name", json.string("Milk Tea")),
  ]))

  // Action: POST /api/drinks
  let req = build_post_request(payload)
  let res = handler(req)

  // Assert: Status is 404
  res.status |> should.equal(404)

  // Assert: Response contains error indicating store not found
  let error_msg = decode_error_message_response(res.body)
  should.be_true(string.contains(error_msg, "store") || string.contains(error_msg, "not found"))
}
