// Integration test for GET /api/drinks/:id/aggregates response headers

import boba_store
import gleeunit/should
import gleam/dict
import gleam/string
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

// Test: Verify response Content-Type is application/json
// Test type: integration (tests HTTP response headers at boundary)
pub fn get_drink_aggregates_returns_json_content_type_test() {
  // Setup: Create drink and rating
  let assert Ok(store) = boba_store.start()
  let assert Ok(drink) = boba_store.create_drink(store, "Taro Milk Tea", "Taro flavored milk tea", 5.25)
  let _ = boba_store.submit_rating(store, drink.id, 4.0, 3.0, 4.0, 4.0)
  
  let handler = router.make_handler(store)

  // Action: GET /api/drinks/:id/aggregates
  let req = build_aggregates_request(drink.id)
  let res = handler(req)

  // Assert: Status is 200
  res.status |> should.equal(200)

  // Assert: Content-Type header indicates JSON
  case dict.get(res.headers, "Content-Type") {
    Ok(content_type) -> {
      should.be_true(string.contains(content_type, "application/json"))
    }
    Error(_) -> should.be_true(False)
  }
}
