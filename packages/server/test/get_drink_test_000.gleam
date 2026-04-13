// Integration test for GET /api/drinks/:id endpoint
// Tests the external HTTP API boundary contract for retrieving a single drink

import gleeunit/should
import gleam/json
import gleam/dict
import gleam/dynamic/decode
import gleam/option.{type Option, None, Some}
import gleam/int
import gleam/float
import boba_store
import boba_types.{type Store, type Drink, Store, Drink}
import boba_validation.{StoreInput, DrinkInput}
import web/boba_router
import web/server.{type Request, type Response, request}

// Test representation of the drink response per boundary contract
type DrinkResponse {
  DrinkResponse(
    id: Int,
    store: StoreRef,
    name: String,
    description: Option(String),
    base_tea_type: Option(String),
    price: Option(Float),
    aggregates: Aggregates,
    created_at: String,
  )
}

type StoreRef {
  StoreRef(id: Int, name: String)
}

type Aggregates {
  Aggregates(
    overall_rating: Float,
    sweetness: Float,
    boba_texture: Float,
    tea_strength: Float,
    count: Int,
  )
}

// Helper: Build GET request to /api/drinks/:id
fn build_get_request(drink_id: Int) -> Request {
  request(
    method: "GET",
    path: "/api/drinks/" <> int.to_string(drink_id),
    headers: dict.from_list([#("accept", "application/json")]),
    body: "",
  )
}

// Helper: Decode drink response from JSON per boundary contract
fn decode_drink_response(json_string: String) -> Result(DrinkResponse, String) {
  let store_decoder = {
    use id <- decode.field("id", decode.int)
    use name <- decode.field("name", decode.string)
    decode.success(StoreRef(id, name))
  }

  let aggregates_decoder = {
    use overall_rating <- decode.field("overall_rating", decode.float)
    use sweetness <- decode.field("sweetness", decode.float)
    use boba_texture <- decode.field("boba_texture", decode.float)
    use tea_strength <- decode.field("tea_strength", decode.float)
    use count <- decode.field("count", decode.int)
    decode.success(Aggregates(overall_rating, sweetness, boba_texture, tea_strength, count))
  }

  let decoder = {
    use id <- decode.field("id", decode.int)
    use store <- decode.field("store", store_decoder)
    use name <- decode.field("name", decode.string)
    use description <- decode.field("description", decode.optional(decode.string))
    use base_tea_type <- decode.field("base_tea_type", decode.optional(decode.string))
    use price <- decode.field("price", decode.optional(decode.float))
    use aggregates <- decode.field("aggregates", aggregates_decoder)
    use created_at <- decode.field("created_at", decode.string)
    decode.success(DrinkResponse(id, store, name, description, base_tea_type, price, aggregates, created_at))
  }

  case json.parse(from: json_string, using: decoder) {
    Ok(drink) -> Ok(drink)
    Error(_) -> Error("Failed to decode drink response")
  }
}

// Helper: Create a test store
fn create_test_store(store) {
  let input = StoreInput(name: "Test Boba Store", address: None, phone: None)
  let assert Ok(created) = boba_store.create_store(store, input)
  created
}

// Helper: Create a test drink
fn create_test_drink(store, store_id) {
  let input = DrinkInput(name: "Classic Milk Tea", store_id: store_id)
  let assert Ok(created) = boba_store.create_drink(store, input)
  created
}

// Test: Given valid drink id, GET /api/drinks/:id returns 200 with complete drink object
pub fn get_drink_valid_id_returns_200_with_store_and_aggregates_test() {
  // Setup: Start store and create a store + drink
  let assert Ok(store) = boba_store.new()
  let created_store = create_test_store(store)
  let created_drink = create_test_drink(store, created_store.id)
  let handler = boba_router.make_handler(store)

  // Action: GET /api/drinks/:id
  let req = build_get_request(created_drink.id)
  let res = handler(req)

  // Assert: Status is 200
  res.status |> should.equal(200)

  // Assert: Response can be decoded per boundary contract
  let decoded = decode_drink_response(res.body)
  let assert Ok(drink) = decoded

  // Assert: Drink ID matches
  drink.id |> should.equal(created_drink.id)

  // Assert: Drink name matches
  drink.name |> should.equal(created_drink.name)

  // Assert: Store reference is populated with id and name
  drink.store.id |> should.equal(created_store.id)
  drink.store.name |> should.equal(created_store.name)

  // Assert: Aggregates object has required fields
  drink.aggregates.overall_rating |> should.equal(0.0)
  drink.aggregates.sweetness |> should.equal(0.0)
  drink.aggregates.boba_texture |> should.equal(0.0)
  drink.aggregates.tea_strength |> should.equal(0.0)
  drink.aggregates.count |> should.equal(0)

  // Assert: created_at is non-empty string
  should.be_true(drink.created_at != "")
}

// Test: Given drink with ratings, aggregates reflect calculated values
pub fn get_drink_with_ratings_returns_correct_aggregates_test() {
  // Setup: Start store, create store + drink + ratings
  let assert Ok(store) = boba_store.new()
  let created_store = create_test_store(store)
  let created_drink = create_test_drink(store, created_store.id)

  // Create ratings for this drink
  let rating_input1 = boba_validation.RatingInput(
    drink_id: created_drink.id,
    rating: 8,
    sweetness: 7,
    boba_texture: 9,
    tea_strength: 6,
    reviewer_name: None,
    review_text: None,
  )
  let rating_input2 = boba_validation.RatingInput(
    drink_id: created_drink.id,
    rating: 9,
    sweetness: 8,
    boba_texture: 8,
    tea_strength: 7,
    reviewer_name: None,
    review_text: None,
  )
  let assert Ok(_) = boba_store.create_rating(store, rating_input1)
  let assert Ok(_) = boba_store.create_rating(store, rating_input2)

  let handler = boba_router.make_handler(store)

  // Action: GET /api/drinks/:id
  let req = build_get_request(created_drink.id)
  let res = handler(req)

  // Assert: Status is 200
  res.status |> should.equal(200)

  // Assert: Response can be decoded
  let decoded = decode_drink_response(res.body)
  let assert Ok(drink) = decoded

  // Assert: Aggregates reflect calculated averages
  drink.aggregates.count |> should.equal(2)
  drink.aggregates.overall_rating |> should.equal(8.5)
  drink.aggregates.sweetness |> should.equal(7.5)
  drink.aggregates.boba_texture |> should.equal(8.5)
  drink.aggregates.tea_strength |> should.equal(6.5)
}

// Test: Given non-existent drink id, GET /api/drinks/:id returns 404
pub fn get_drink_nonexistent_id_returns_404_test() {
  // Setup: Start store with no drinks
  let assert Ok(store) = boba_store.new()
  let handler = boba_router.make_handler(store)

  // Action: GET /api/drinks/99999 (non-existent ID)
  let req = build_get_request(99999)
  let res = handler(req)

  // Assert: Status is 404
  res.status |> should.equal(404)

  // Assert: Response body contains error
  should.be_true(dict.has_key(res.headers, "Content-Type"))
}

// Test: Given invalid drink id format, GET /api/drinks/:id returns 400
pub fn get_drink_invalid_id_format_returns_400_test() {
  // Setup: Start store
  let assert Ok(store) = boba_store.new()
  let handler = boba_router.make_handler(store)

  // Action: GET /api/drinks/invalid
  let req = request(
    method: "GET",
    path: "/api/drinks/invalid",
    headers: dict.from_list([#("accept", "application/json")]),
    body: "",
  )
  let res = handler(req)

  // Assert: Status is 400 (bad request for invalid ID format)
  res.status |> should.equal(400)
}

// Test: Response Content-Type header is application/json
pub fn get_drink_returns_json_content_type_test() {
  // Setup: Start store with a drink
  let assert Ok(store) = boba_store.new()
  let created_store = create_test_store(store)
  let created_drink = create_test_drink(store, created_store.id)
  let handler = boba_router.make_handler(store)

  // Action: GET /api/drinks/:id
  let req = build_get_request(created_drink.id)
  let res = handler(req)

  // Assert: Content-Type header is application/json
  case dict.get(res.headers, "Content-Type") {
    Ok(content_type) -> {
      should.be_true(content_type == "application/json")
    }
    Error(_) -> should.fail()
  }
}

// Test: Response contains all required boundary contract fields
pub fn get_drink_response_has_all_boundary_contract_fields_test() {
  // Setup: Start store with a drink
  let assert Ok(store) = boba_store.new()
  let created_store = create_test_store(store)
  let created_drink = create_test_drink(store, created_store.id)
  let handler = boba_router.make_handler(store)

  // Action: GET /api/drinks/:id
  let req = build_get_request(created_drink.id)
  let res = handler(req)

  // Assert: Parse JSON and verify all boundary contract fields exist
  let field_decoder = {
    use id <- decode.field("id", decode.int)
    use store <- decode.field("store", decode.dict(decode.string, decode.dynamic))
    use name <- decode.field("name", decode.string)
    use description <- decode.field("description", decode.optional(decode.string))
    use base_tea_type <- decode.field("base_tea_type", decode.optional(decode.string))
    use price <- decode.field("price", decode.optional(decode.float))
    use aggregates <- decode.field("aggregates", decode.dict(decode.string, decode.dynamic))
    use created_at <- decode.field("created_at", decode.string)
    decode.success(#(id, store, name, description, base_tea_type, price, aggregates, created_at))
  }

  case json.parse(from: res.body, using: field_decoder) {
    Ok(#(id, store_dict, name, _description, _base_tea_type, _price, agg_dict, created_at)) -> {
      // Verify id is integer
      id |> should.equal(created_drink.id)

      // Verify store has id and name fields
      should.be_true(dict.has_key(store_dict, "id"))
      should.be_true(dict.has_key(store_dict, "name"))

      // Verify name is string
      should.be_true(name != "")

      // Verify aggregates has all required fields
      should.be_true(dict.has_key(agg_dict, "overall_rating"))
      should.be_true(dict.has_key(agg_dict, "sweetness"))
      should.be_true(dict.has_key(agg_dict, "boba_texture"))
      should.be_true(dict.has_key(agg_dict, "tea_strength"))
      should.be_true(dict.has_key(agg_dict, "count"))

      // Verify created_at is non-empty
      should.be_true(created_at != "")
    }
    Error(_) -> should.fail()
  }
}
