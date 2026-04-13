// Integration test for GET /api/drinks/:id/aggregates endpoint
// Tests the external HTTP API boundary contract for retrieving aggregate ratings

import boba_store
import gleeunit/should
import gleam/json
import gleam/dict
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

// Test-only representation of AggregateRatings response
type TestAggregateRatings {
  TestAggregateRatings(
    drink_id: String,
    overall_rating: Float,
    sweetness: Float,
    boba_texture: Float,
    tea_strength: Float,
    count: Int,
  )
}

// Helper: Decode aggregate ratings response from JSON
fn decode_aggregates_response(json_string: String) -> Result(TestAggregateRatings, String) {
  let decoder = {
    use drink_id <- decode.field("drink_id", decode.string)
    use overall_rating <- decode.field("overall_rating", decode.float)
    use sweetness <- decode.field("sweetness", decode.float)
    use boba_texture <- decode.field("boba_texture", decode.float)
    use tea_strength <- decode.field("tea_strength", decode.float)
    use count <- decode.field("count", decode.int)
    decode.success(TestAggregateRatings(drink_id, overall_rating, sweetness, boba_texture, tea_strength, count))
  }

  case json.parse(from: json_string, using: decoder) {
    Ok(aggregates) -> Ok(aggregates)
    Error(_) -> Error("Failed to decode aggregates response")
  }
}

// Test: Given drink with ratings exists, when GET /api/drinks/:id/aggregates, then returns 200 with calculated averages
// Test type: integration (tests HTTP API boundary contract)
// Acceptance criterion: Given drink with ratings GET /api/drinks/:id/aggregates, then returns 200 with average values and count
pub fn get_drink_aggregates_with_ratings_returns_200_with_averages_test() {
  // Setup: Create drink and submit ratings via store API (public interface boundary)
  let assert Ok(store) = boba_store.start()
  let assert Ok(drink) = boba_store.create_drink(store, "Classic Milk Tea", "Black milk tea with boba", 5.50)
  
  // Submit multiple ratings to calculate averages
  let _ = boba_store.submit_rating(store, drink.id, 4.5, 3.5, 4.0, 4.5)  // overall=4.5, sweetness=3.5, texture=4.0, strength=4.5
  let _ = boba_store.submit_rating(store, drink.id, 3.5, 4.0, 3.5, 3.0)  // overall=3.5, sweetness=4.0, texture=3.5, strength=3.0
  let _ = boba_store.submit_rating(store, drink.id, 5.0, 5.0, 5.0, 5.0)  // overall=5.0, sweetness=5.0, texture=5.0, strength=5.0
  
  let handler = router.make_handler(store)

  // Action: GET /api/drinks/:id/aggregates
  let req = build_aggregates_request(drink.id)
  let res = handler(req)

  // Assert: Status is 200
  res.status |> should.equal(200)

  // Assert: Response body contains correct aggregate values
  let assert Ok(aggregates) = decode_aggregates_response(res.body)
  
  // drink_id matches the requested drink
  aggregates.drink_id |> should.equal(drink.id)
  
  // overall_rating is average of (4.5 + 3.5 + 5.0) / 3 = 4.333...
  should.be_true(aggregates.overall_rating >=. 4.3 && aggregates.overall_rating <=. 4.4)

  // sweetness is average of (3.5 + 4.0 + 5.0) / 3 = 4.166...
  should.be_true(aggregates.sweetness >=. 4.1 && aggregates.sweetness <=. 4.2)

  // boba_texture is average of (4.0 + 3.5 + 5.0) / 3 = 4.166...
  should.be_true(aggregates.boba_texture >=. 4.1 && aggregates.boba_texture <=. 4.2)

  // tea_strength is average of (4.5 + 3.0 + 5.0) / 3 = 4.166...
  should.be_true(aggregates.tea_strength >=. 4.1 && aggregates.tea_strength <=. 4.2)
  
  // count is 3 (three ratings submitted)
  aggregates.count |> should.equal(3)
}
