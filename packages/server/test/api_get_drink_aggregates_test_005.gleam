// Integration test for GET /api/drinks/:id/aggregates drink_id field accuracy

import boba_store
import gleeunit/should
import gleam/json
import gleam/dict
import gleam/string
import gleam/dynamic/decode
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

// Test: Verify drink_id in response matches the requested UUID
// Test type: integration (tests data accuracy at HTTP boundary)
pub fn get_drink_aggregates_response_contains_correct_drink_id_test() {
  // Setup: Create multiple drinks to ensure correct drink is returned
  let assert Ok(store) = boba_store.start()
  let assert Ok(drink_a) = boba_store.create_drink(store, "Drink A", "First drink", 4.00)
  let assert Ok(drink_b) = boba_store.create_drink(store, "Drink B", "Second drink", 5.00)
  let assert Ok(target_drink) = boba_store.create_drink(store, "Target Drink", "The one we're testing", 5.50)
  let assert Ok(drink_c) = boba_store.create_drink(store, "Drink C", "Third drink", 6.00)
  
  // Submit ratings to target drink only
  let _ = boba_store.submit_rating(store, target_drink.id, 5.0, 5.0, 5.0, 5.0)
  
  let handler = router.make_handler(store)

  // Action: GET /api/drinks/:id/aggregates for target_drink
  let req = build_aggregates_request(target_drink.id)
  let res = handler(req)

  // Assert: Status is 200
  res.status |> should.equal(200)

  // Assert: drink_id in response matches target_drink.id exactly
  let decoder = {
    use drink_id <- decode.field("drink_id", decode.string)
    decode.success(drink_id)
  }

  case json.parse(from: res.body, using: decoder) {
    Ok(response_drink_id) -> {
      response_drink_id |> should.equal(target_drink.id)
      // Verify it's a UUID format (contains hyphens and is correct length)
      should.be_true(string.length(response_drink_id) == 36)
      should.be_true(string.contains(response_drink_id, "-"))
    }
    Error(_) -> should.be_true(False)
  }
}
