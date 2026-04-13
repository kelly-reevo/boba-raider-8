// Integration test for GET /api/drinks/:id/aggregates endpoint - empty ratings case

import boba_store
import gleeunit/should
import gleam/json
import gleam/dict
import gleam/dynamic/decode
import gleam/option.{type Option, None}
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

// Test-only representation of AggregateRatings response with nullable fields
type TestNullableAggregateRatings {
  TestNullableAggregateRatings(
    drink_id: String,
    overall_rating: Option(Float),
    sweetness: Option(Float),
    boba_texture: Option(Float),
    tea_strength: Option(Float),
    count: Int,
  )
}

// Helper: Decode aggregate ratings response with nullable fields from JSON
fn decode_nullable_aggregates_response(json_string: String) -> Result(TestNullableAggregateRatings, String) {
  let decoder = {
    use drink_id <- decode.field("drink_id", decode.string)
    use overall_rating <- decode.field("overall_rating", decode.optional(decode.float))
    use sweetness <- decode.field("sweetness", decode.optional(decode.float))
    use boba_texture <- decode.field("boba_texture", decode.optional(decode.float))
    use tea_strength <- decode.field("tea_strength", decode.optional(decode.float))
    use count <- decode.field("count", decode.int)
    decode.success(TestNullableAggregateRatings(drink_id, overall_rating, sweetness, boba_texture, tea_strength, count))
  }

  case json.parse(from: json_string, using: decoder) {
    Ok(aggregates) -> Ok(aggregates)
    Error(_) -> Error("Failed to decode aggregates response")
  }
}

// Test: Given drink with no ratings, when GET /api/drinks/:id/aggregates, then returns 200 with null averages and count 0
// Test type: integration (tests HTTP API boundary contract)
// Acceptance criterion: Given drink with no ratings, then returns 200 with null averages and count 0
pub fn get_drink_aggregates_no_ratings_returns_nulls_and_zero_count_test() {
  // Setup: Create drink without submitting any ratings
  let assert Ok(store) = boba_store.start()
  let assert Ok(drink) = boba_store.create_drink(store, "Jasmine Green Tea", "Green tea with jasmine", 4.50)
  // Note: No ratings submitted for this drink
  
  let handler = router.make_handler(store)

  // Action: GET /api/drinks/:id/aggregates
  let req = build_aggregates_request(drink.id)
  let res = handler(req)

  // Assert: Status is 200
  res.status |> should.equal(200)

  // Assert: Response body contains null averages and count 0
  let assert Ok(aggregates) = decode_nullable_aggregates_response(res.body)
  
  // drink_id matches the requested drink
  aggregates.drink_id |> should.equal(drink.id)
  
  // overall_rating is null (None)
  aggregates.overall_rating |> should.equal(None)
  
  // sweetness is null (None)
  aggregates.sweetness |> should.equal(None)
  
  // boba_texture is null (None)
  aggregates.boba_texture |> should.equal(None)
  
  // tea_strength is null (None)
  aggregates.tea_strength |> should.equal(None)
  
  // count is 0 (no ratings)
  aggregates.count |> should.equal(0)
}
