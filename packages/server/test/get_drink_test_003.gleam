// Integration test for GET /api/drinks/:id edge cases
// Tests boundary contract error handling for invalid inputs

import gleeunit/should
import gleam/dict
import boba_store
import web/boba_router
import web/server.{type Request, request}

// Test: Invalid ID format (non-numeric) returns 400
pub fn get_drink_invalid_id_format_returns_400_test() {
  // Setup: Start store
  let assert Ok(store) = boba_store.new()
  let handler = boba_router.make_handler(store)

  // Action: GET with non-numeric ID
  let req = request(
    method: "GET",
    path: "/api/drinks/abc123",
    headers: dict.from_list([#("accept", "application/json")]),
    body: "",
  )
  let res = handler(req)

  // Assert: Status is 400 (bad request)
  res.status |> should.equal(400)
}

// Test: Negative ID returns 404
pub fn get_drink_negative_id_returns_404_test() {
  // Setup: Start store
  let assert Ok(store) = boba_store.new()
  let handler = boba_router.make_handler(store)

  // Action: GET with negative ID
  let req = request(
    method: "GET",
    path: "/api/drinks/-1",
    headers: dict.from_list([#("accept", "application/json")]),
    body: "",
  )
  let res = handler(req)

  // Assert: Status is 404
  res.status |> should.equal(404)
}

// Test: Zero ID returns 404
pub fn get_drink_zero_id_returns_404_test() {
  // Setup: Start store
  let assert Ok(store) = boba_store.new()
  let handler = boba_router.make_handler(store)

  // Action: GET with zero ID
  let req = request(
    method: "GET",
    path: "/api/drinks/0",
    headers: dict.from_list([#("accept", "application/json")]),
    body: "",
  )
  let res = handler(req)

  // Assert: Status is 404
  res.status |> should.equal(404)
}
