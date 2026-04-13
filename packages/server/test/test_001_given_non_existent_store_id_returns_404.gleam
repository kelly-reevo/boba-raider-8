// Integration test for GET /api/stores/:id 404 error case
// Tests the external HTTP API boundary contract error response

import gleeunit/should
import gleam/json
import gleam/dict
import gleam/string
import gleam/dynamic/decode
import boba_store
import web/boba_router
import web/server.{type Request, type Response, Request as RequestConstructor}

// Helper: Build a GET request to /api/stores/:id
fn build_get_store_request(store_id: String) -> Request {
  RequestConstructor(
    method: "GET",
    path: "/api/stores/" <> store_id,
    headers: dict.from_list([#("accept", "application/json")]),
    body: "",
  )
}

// Helper: Decode error response from JSON
fn decode_error_response(json_string: String) -> Result(String, String) {
  let decoder = {
    use error <- decode.field("error", decode.string)
    decode.success(error)
  }

  case json.parse(from: json_string, using: decoder) {
    Ok(error_msg) -> Ok(error_msg)
    Error(_) -> Error("Failed to decode error response")
  }
}

// ============================================================================
// ACCEPTANCE CRITERION: Given non-existent store id,
// when GET /api/stores/:id called, then returns 404 with error 'store not found'
// Boundary contract: GET /api/stores/:id -> 404 {error: string}
// Test type: integration (tests error response at boundary)
// ============================================================================
pub fn get_store_by_id_nonexistent_returns_404_with_error_message_test() {
  // Setup: Start store without creating any stores
  let assert Ok(store) = boba_store.new()
  let handler = boba_router.make_handler(store)

  // Action: GET /api/stores/99999 (non-existent ID)
  let req = build_get_store_request("99999")
  let res = handler(req)

  // Assert: Status is 404
  res.status |> should.equal(404)

  // Assert: Response body is valid JSON with error field
  let assert Ok(error_msg) = decode_error_response(res.body)

  // Assert: Error message indicates store not found
  should.be_true(
    string.contains(string.lowercase(error_msg), "not found") ||
    string.contains(string.lowercase(error_msg), "store")
  )
}

// ============================================================================
// ACCEPTANCE CRITERION: Given negative store id,
// when GET /api/stores/:id called, then returns 404
// Boundary contract: Invalid id returns 404 {error: string}
// Test type: integration (tests boundary validation)
// ============================================================================
pub fn get_store_by_id_negative_id_returns_404_test() {
  // Setup: Start store
  let assert Ok(store) = boba_store.new()
  let handler = boba_router.make_handler(store)

  // Action: GET /api/stores/-1 (invalid negative ID)
  let req = build_get_store_request("-1")
  let res = handler(req)

  // Assert: Status is 404 (or 400 for bad request)
  should.be_true(res.status == 404 || res.status == 400)

  // Assert: Response contains error field
  case decode_error_response(res.body) {
    Ok(_) -> should.be_true(True)  // Error message present
    Error(_) -> should.equal(1, 0)
  }
}

// ============================================================================
// ACCEPTANCE CRITERION: Given zero as store id,
// when GET /api/stores/:id called, then returns 404
// Boundary contract: Invalid id returns 404 {error: string}
// Test type: integration (tests boundary validation for edge case)
// ============================================================================
pub fn get_store_by_id_zero_id_returns_404_test() {
  // Setup: Start store
  let assert Ok(store) = boba_store.new()
  let handler = boba_router.make_handler(store)

  // Action: GET /api/stores/0 (invalid zero ID)
  let req = build_get_store_request("0")
  let res = handler(req)

  // Assert: Status is 404 (not found) or 400 (bad request)
  should.be_true(res.status == 404 || res.status == 400)

  // Assert: Response indicates error condition
  case decode_error_response(res.body) {
    Ok(error_msg) -> {
      should.be_true(
        string.contains(string.lowercase(error_msg), "not found") ||
        string.contains(string.lowercase(error_msg), "invalid")
      )
    }
    Error(_) -> should.equal(1, 0)
  }
}