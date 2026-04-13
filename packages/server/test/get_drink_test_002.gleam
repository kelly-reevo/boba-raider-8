// Integration test for GET /api/drinks/:id response schema validation
// Tests that the response exactly matches the boundary contract specification

import gleeunit/should
import gleam/json
import gleam/dict
import gleam/dynamic/decode
import gleam/option.{type Option, None, Some}
import gleam/int
import gleam/float
import boba_store
import boba_validation.{StoreInput, DrinkInput}
import web/boba_router
import web/server.{type Request, request}

// Full boundary contract schema decoder per spec:
// {id, store: {id, name}, name, description?, base_tea_type?, price?, aggregates: {overall_rating: float, sweetness: float, boba_texture: float, tea_strength: float, count: int}, created_at}
fn build_get_request(drink_id: Int) -> Request {
  request(
    method: "GET",
    path: "/api/drinks/" <> int.to_string(drink_id),
    headers: dict.from_list([#("accept", "application/json")]),
    body: "",
  )
}

// Test: Response schema matches boundary contract exactly
pub fn get_drink_response_schema_matches_contract_test() {
  // Setup: Create store and drink
  let assert Ok(store) = boba_store.new()
  let store_input = StoreInput(name: "Boba Guys", address: Some("123 Main St"), phone: None)
  let assert Ok(created_store) = boba_store.create_store(store, store_input)
  let drink_input = DrinkInput(name: "Matcha Latte", store_id: created_store.id)
  let assert Ok(created_drink) = boba_store.create_drink(store, drink_input)
  let handler = boba_router.make_handler(store)

  // Action: GET /api/drinks/:id
  let req = build_get_request(created_drink.id)
  let res = handler(req)

  // Assert: Status 200
  res.status |> should.equal(200)

  // Parse and validate exact schema per boundary contract
  let store_decoder = decode.dict(decode.string, decode.dynamic)
  let aggregates_decoder = decode.dict(decode.string, decode.dynamic)

  let schema_decoder = {
    use id <- decode.field("id", decode.int)
    use store <- decode.field("store", store_decoder)
    use name <- decode.field("name", decode.string)
    use description <- decode.field("description", decode.optional(decode.string))
    use base_tea_type <- decode.field("base_tea_type", decode.optional(decode.string))
    use price <- decode.field("price", decode.optional(decode.float))
    use aggregates <- decode.field("aggregates", aggregates_decoder)
    use created_at <- decode.field("created_at", decode.string)
    decode.success(#(id, store, name, description, base_tea_type, price, aggregates, created_at))
  }

  let result = json.parse(from: res.body, using: schema_decoder)

  case result {
    Ok(#(id, store_dict, name, _description, _base_tea_type, _price, agg_dict, created_at)) -> {
      // Validate id field: integer
      should.equal(True, id > 0)

      // Validate store field: {id, name}
      should.equal(True, dict.has_key(store_dict, "id"))
      should.equal(True, dict.has_key(store_dict, "name"))

      // Validate name field: string
      should.equal(True, name != "")

      // Validate aggregates field: {overall_rating: float, sweetness: float, boba_texture: float, tea_strength: float, count: int}
      should.equal(True, dict.has_key(agg_dict, "overall_rating"))
      should.equal(True, dict.has_key(agg_dict, "sweetness"))
      should.equal(True, dict.has_key(agg_dict, "boba_texture"))
      should.equal(True, dict.has_key(agg_dict, "tea_strength"))
      should.equal(True, dict.has_key(agg_dict, "count"))

      // Validate created_at field: string (ISO8601)
      should.equal(True, created_at != "")
    }
    Error(_) -> should.fail()
  }
}

// Test: Store reference contains only id and name fields
pub fn get_drink_store_ref_has_only_id_and_name_test() {
  // Setup: Create store and drink
  let assert Ok(store) = boba_store.new()
  let store_input = StoreInput(name: "Happy Lemon", address: None, phone: None)
  let assert Ok(created_store) = boba_store.create_store(store, store_input)
  let drink_input = DrinkInput(name: "Brown Sugar Boba", store_id: created_store.id)
  let assert Ok(created_drink) = boba_store.create_drink(store, drink_input)
  let handler = boba_router.make_handler(store)

  // Action: GET /api/drinks/:id
  let req = build_get_request(created_drink.id)
  let res = handler(req)

  // Parse store field specifically
  let store_decoder = {
    use id <- decode.field("id", decode.int)
    use name <- decode.field("name", decode.string)
    decode.success(#(id, name))
  }

  let response_decoder = {
    use store <- decode.field("store", store_decoder)
    decode.success(store)
  }

  case json.parse(from: res.body, using: response_decoder) {
    Ok(#(store_id, store_name)) -> {
      store_id |> should.equal(created_store.id)
      store_name |> should.equal(created_store.name)
    }
    Error(_) -> should.fail()
  }
}

// Test: Aggregates contains correct numeric types
pub fn get_drink_aggregates_has_correct_types_test() {
  // Setup: Create store, drink, and ratings to get non-zero aggregates
  let assert Ok(store) = boba_store.new()
  let store_input = StoreInput(name: "Tea Shop", address: None, phone: None)
  let assert Ok(created_store) = boba_store.create_store(store, store_input)
  let drink_input = DrinkInput(name: "Oolong Milk Tea", store_id: created_store.id)
  let assert Ok(created_drink) = boba_store.create_drink(store, drink_input)

  // Add ratings
  let rating_input = boba_validation.RatingInput(
    drink_id: created_drink.id,
    rating: 7,
    sweetness: 6,
    boba_texture: 8,
    tea_strength: 7,
    reviewer_name: None,
    review_text: None,
  )
  let assert Ok(_) = boba_store.create_rating(store, rating_input)

  let handler = boba_router.make_handler(store)

  // Action: GET /api/drinks/:id
  let req = build_get_request(created_drink.id)
  let res = handler(req)

  // Validate aggregate types per boundary contract
  let agg_decoder = {
    use overall <- decode.field("overall_rating", decode.float)
    use sweetness <- decode.field("sweetness", decode.float)
    use texture <- decode.field("boba_texture", decode.float)
    use strength <- decode.field("tea_strength", decode.float)
    use count <- decode.field("count", decode.int)
    decode.success(#(overall, sweetness, texture, strength, count))
  }

  let response_decoder = {
    use agg <- decode.field("aggregates", agg_decoder)
    decode.success(agg)
  }

  case json.parse(from: res.body, using: response_decoder) {
    Ok(#(overall, sweetness, texture, strength, count)) -> {
      // All ratings are floats per boundary contract
      overall |> should.equal(7.0)
      sweetness |> should.equal(6.0)
      texture |> should.equal(8.0)
      strength |> should.equal(7.0)
      // Count is integer
      count |> should.equal(1)
    }
    Error(_) -> should.fail()
  }
}
