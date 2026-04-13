// Integration test for GET /api/drinks/:id/aggregates endpoint - not found case

import boba_store
import gleeunit/should
import gleam/dict
import web/router
import web/server

// Helper: Build a GET request to /api/drinks/:id/aggregates
fn build_aggregates_request(drink_id: String) -> server.Request {
  server.Request(
    method: "GET",
    path: "/api/drinks/" <> drink_id <> "/aggregates",
    headers: dict.from_list([#("accept", "application/json")]),
    body: "",
  )
}

// Test: Given non-existent drink ID, when GET /api/drinks/:id/aggregates, then returns 404
// Test type: integration (tests HTTP API boundary contract error handling)
// Boundary contract: 404 returned when drink does not exist
pub fn get_drink_aggregates_nonexistent_drink_returns_404_test() {
  // Setup: Start store but do not create any drinks
  let assert Ok(store) = boba_store.start()
  let handler = router.make_handler(store)
  
  // Use a valid UUID format that does not exist in the store
  let nonexistent_drink_id = "550e8400-e29b-41d4-a716-446655440000"

  // Action: GET /api/drinks/:id/aggregates with non-existent ID
  let req = build_aggregates_request(nonexistent_drink_id)
  let res = handler(req)

  // Assert: Status is 404
  res.status |> should.equal(404)
}
