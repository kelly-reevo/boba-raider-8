// Integration test for GET /api/drinks/:id/aggregates response schema validation

import boba_store
import gleeunit/should
import gleam/json
import gleam/dict
import gleam/string
import gleam/dynamic/decode
import gleam/option.{Some, None}
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

// Test: Verify response JSON schema matches boundary contract: {drink_id: uuid, overall_rating: float|null, sweetness: float|null, boba_texture: float|null, tea_strength: float|null, count: int}
// Test type: integration (tests response schema validation at boundary)
pub fn get_drink_aggregates_response_schema_validation_test() {
  // Setup: Create drink with ratings
  let assert Ok(store) = boba_store.start()
  let assert Ok(drink) = boba_store.create_drink(store, "Oolong Milk Tea", "Oolong tea with milk", 5.00)
  let _ = boba_store.submit_rating(store, drink.id, 4.5, 4.0, 4.5, 4.0)
  
  let handler = router.make_handler(store)

  // Action: GET /api/drinks/:id/aggregates
  let req = build_aggregates_request(drink.id)
  let res = handler(req)

  // Assert: Status is 200
  res.status |> should.equal(200)

  // Assert: Parse the JSON response according to boundary contract schema
  let schema_decoder = {
    use drink_id <- decode.field("drink_id", decode.string)
    use overall_rating <- decode.field("overall_rating", decode.optional(decode.float))
    use sweetness <- decode.field("sweetness", decode.optional(decode.float))
    use boba_texture <- decode.field("boba_texture", decode.optional(decode.float))
    use tea_strength <- decode.field("tea_strength", decode.optional(decode.float))
    use count <- decode.field("count", decode.int)
    decode.success(#(drink_id, overall_rating, sweetness, boba_texture, tea_strength, count))
  }

  case json.parse(from: res.body, using: schema_decoder) {
    Ok(#(drink_id, overall_rating, sweetness, boba_texture, tea_strength, count)) -> {
      // drink_id: UUID string (non-empty)
      should.be_true(string.length(drink_id) > 0)
      
      // overall_rating: float|null (validated by option type)
      // sweetness: float|null
      // boba_texture: float|null  
      // tea_strength: float|null
      
      // count: int (non-negative)
      should.be_true(count >= 0)
      
      // With ratings present, count should be 1 and ratings should be Some(float)
      count |> should.equal(1)
      case overall_rating {
        Some(_) -> should.be_true(True)
        None -> should.be_true(False)
      }
      case sweetness {
        Some(_) -> should.be_true(True)
        None -> should.be_true(False)
      }
      case boba_texture {
        Some(_) -> should.be_true(True)
        None -> should.be_true(False)
      }
      case tea_strength {
        Some(_) -> should.be_true(True)
        None -> should.be_true(False)
      }
    }
    Error(_) -> should.be_true(False)
  }
}
