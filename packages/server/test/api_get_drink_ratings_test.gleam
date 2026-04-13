import drink_store
import gleam/dict
import gleam/option.{None}
import gleam/string
import gleeunit
import gleeunit/should
import rating_service
import web/router
import web/server

pub fn main() {
  gleeunit.main()
}

// Test helper to create a request
fn make_get_request(path: String) -> server.Request {
  server.Request(
    method: "GET",
    path: path,
    headers: dict.new(),
    body: "",
  )
}

// Create test context with initialized services
fn create_test_context() -> router.Context {
  let assert Ok(store) = drink_store.start()
  let assert Ok(service) = rating_service.start(store)
  router.Context(rating_service: service)
}

// Test that endpoint returns 404 for non-existent drink
pub fn nonexistent_drink_returns_404_test() {
  let ctx = create_test_context()
  let handler = router.make_handler_with_context(ctx)

  let req = make_get_request("/api/drinks/nonexistent-drink/ratings")
  let res = handler(req)

  should.equal(res.status, 404)
}

// Test that pagination parameters are parsed without error
pub fn pagination_params_parsed_test() {
  let ctx = create_test_context()
  let handler = router.make_handler_with_context(ctx)

  // Test with limit parameter - should parse correctly (but still 404 for missing drink)
  let req = make_get_request("/api/drinks/test-drink/ratings?limit=5")
  let res = handler(req)

  // Returns 404 because drink doesn't exist, but shouldn't crash on parsing
  should.equal(res.status, 404)
}

// Test that both limit and offset are parsed
pub fn limit_and_offset_parsed_test() {
  let ctx = create_test_context()
  let handler = router.make_handler_with_context(ctx)

  let req = make_get_request("/api/drinks/test-drink/ratings?limit=10&offset=5")
  let res = handler(req)

  // Returns 404 because drink doesn't exist, but should parse params correctly
  should.equal(res.status, 404)
}

// Test response structure for valid request (when drink exists)
pub fn get_drink_ratings_response_structure_test() {
  // Initialize stores
  let assert Ok(drink_store) = drink_store.start()
  let assert Ok(rating_svc) = rating_service.start(drink_store)
  let ctx = router.Context(rating_service: rating_svc)
  let handler = router.make_handler_with_context(ctx)

  // Create a drink first
  let store_input = drink_store.CreateDrinkInput(
    store_id: "store-1",
    name: "Test Drink",
    description: None,
    base_tea_type: None,
    price: None,
  )
  let assert Ok(drink) = drink_store.create_drink(drink_store, store_input)

  // Now request ratings for that drink
  let req = make_get_request("/api/drinks/" <> drink.id <> "/ratings")
  let res = handler(req)

  should.equal(res.status, 200)

  // Verify response body contains expected JSON structure by checking content type
  let content_type = case dict.get(res.headers, "Content-Type") {
    Ok(ct) -> ct
    Error(_) -> ""
  }
  should.equal(content_type, "application/json")

  // Verify body contains key fields by simple string checks
  should.be_true(string.contains(res.body, "ratings"))
  should.be_true(string.contains(res.body, "total"))
  should.be_true(string.contains(res.body, "limit"))
  should.be_true(string.contains(res.body, "offset"))
}
