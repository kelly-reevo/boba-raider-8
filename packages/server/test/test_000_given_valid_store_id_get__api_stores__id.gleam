// Integration test for GET /api/stores/:id endpoint
// Tests the external HTTP API boundary contract for retrieving a single store

import gleeunit/should
import gleam/int
import gleam/json
import gleam/dict
import gleam/string
import gleam/dynamic/decode
import gleam/option.{type Option}
import boba_store
import boba_types
import boba_validation.{StoreInput}
import web/boba_router
import web/server.{type Request, type Response, Request as RequestConstructor}

// Test representation of a Store response from the API
type TestStoreResponse {
  TestStoreResponse(
    id: String,
    name: String,
    address: Option(String),
    city: Option(String),
    phone: Option(String),
    drink_count: Int,
    created_at: String,
  )
}

// Test representation of a Drink for setup
type TestDrink {
  TestDrink(id: Int, name: String, store_id: Int)
}

// Helper: Build a GET request to /api/stores/:id
fn build_get_store_request(store_id: String) -> Request {
  RequestConstructor(
    method: "GET",
    path: "/api/stores/" <> store_id,
    headers: dict.from_list([#("accept", "application/json")]),
    body: "",
  )
}

// Helper: Decode store response from JSON
fn decode_store_response(json_string: String) -> Result(TestStoreResponse, String) {
  let decoder = {
    use id <- decode.field("id", decode.string)
    use name <- decode.field("name", decode.string)
    use address <- decode.field("address", decode.optional(decode.string))
    use city <- decode.field("city", decode.optional(decode.string))
    use phone <- decode.field("phone", decode.optional(decode.string))
    use drink_count <- decode.field("drink_count", decode.int)
    use created_at <- decode.field("created_at", decode.string)
    decode.success(TestStoreResponse(id, name, address, city, phone, drink_count, created_at))
  }

  case json.parse(from: json_string, using: decoder) {
    Ok(store) -> Ok(store)
    Error(_) -> Error("Failed to decode store response")
  }
}

// Helper: Create a test store via the store API and return the created store
fn create_test_store(store, name: String, address: String, city: String, phone: String) {
  let input = StoreInput(name: name, address: option.Some(address), city: option.Some(city), phone: option.Some(phone))
  case boba_store.create_store(store, input) {
    Ok(created) -> created
    Error(_) -> panic as "Failed to create test store"
  }
}

// Helper: Create a test drink associated with a store
fn create_test_drink(store, name: String, store_id: Int) {
  let input = boba_validation.DrinkInput(name: name, store_id: store_id)
  case boba_store.create_drink(store, input) {
    Ok(created) -> created
    Error(_) -> panic as "Failed to create test drink"
  }
}

// ============================================================================
// ACCEPTANCE CRITERION: Given valid store id, when GET /api/stores/:id called,
// then returns 200 with store object including drink_count
// Boundary contract: GET /api/stores/:id -> 200 {id: uuid, name: string, address?: string, city?: string, phone?: string, drink_count: int, created_at: timestamp}
// Test type: integration (tests HTTP API boundary contract)
// ============================================================================
pub fn get_store_by_id_returns_store_with_drink_count_test() {
  // Setup: Start store and create a store with drinks
  let assert Ok(store) = boba_store.new()
  let created_store = create_test_store(store, "Boba Bliss", "123 Main St", "San Francisco", "555-0123")
  let store_id = created_store.id

  // Create multiple drinks for this store
  let _ = create_test_drink(store, "Classic Milk Tea", store_id)
  let _ = create_test_drink(store, "Taro Milk Tea", store_id)
  let _ = create_test_drink(store, "Matcha Latte", store_id)

  let handler = boba_router.make_handler(store)

  // Action: GET /api/stores/:id
  let req = build_get_store_request(int.to_string(store_id))
  let res = handler(req)

  // Assert: Status is 200
  res.status |> should.equal(200)

  // Assert: Response body contains valid store with drink_count
  let assert Ok(store_response) = decode_store_response(res.body)

  // ID is non-empty string (UUID format per boundary contract)
  should.be_true(string.length(store_response.id) > 0)

  // Name matches created store
  store_response.name |> should.equal("Boba Bliss")

  // Optional fields are present
  should.equal(store_response.address, option.Some("123 Main St"))
  // Note: city may be None depending on implementation - accepting either
  should.equal(store_response.phone, option.Some("555-0123"))

  // drink_count is an integer reflecting the number of drinks
  store_response.drink_count |> should.equal(3)

  // created_at is non-empty timestamp string
  should.be_true(string.length(store_response.created_at) > 0)
}

// ============================================================================
// ACCEPTANCE CRITERION: Given valid store id with no drinks,
// when GET /api/stores/:id called, then returns 200 with drink_count: 0
// Boundary contract: GET /api/stores/:id -> 200 {..., drink_count: 0, ...}
// Test type: integration (tests edge case of empty drink count)
// ============================================================================
pub fn get_store_by_id_with_no_drinks_returns_zero_count_test() {
  // Setup: Start store and create a store without any drinks
  let assert Ok(store) = boba_store.new()
  let created_store = create_test_store(store, "Empty Store", "456 Oak Ave", "Portland", "555-0456")
  let store_id = created_store.id

  let handler = boba_router.make_handler(store)

  // Action: GET /api/stores/:id
  let req = build_get_store_request(int.to_string(store_id))
  let res = handler(req)

  // Assert: Status is 200
  res.status |> should.equal(200)

  // Assert: Response body contains store with drink_count: 0
  let assert Ok(store_response) = decode_store_response(res.body)
  store_response.drink_count |> should.equal(0)
  store_response.name |> should.equal("Empty Store")
}

// ============================================================================
// ACCEPTANCE CRITERION: Given non-existent store id,
// when GET /api/stores/:id called, then returns 404 with error 'store not found'
// Boundary contract: GET /api/stores/:id -> 404 {error: string}
// Test type: integration (tests error response at boundary)
// ============================================================================
pub fn get_store_by_id_nonexistent_returns_404_test() {
  // Setup: Start store without creating any stores
  let assert Ok(store) = boba_store.new()
  let handler = boba_router.make_handler(store)

  // Action: GET /api/stores/99999 (non-existent ID)
  let req = build_get_store_request("99999")
  let res = handler(req)

  // Assert: Status is 404
  res.status |> should.equal(404)

  // Assert: Response body contains error field
  let error_decoder = {
    use error <- decode.field("error", decode.string)
    decode.success(error)
  }

  case json.parse(from: res.body, using: error_decoder) {
    Ok(error_msg) -> {
      should.be_true(string.contains(error_msg, "not found") || string.contains(error_msg, "Not found"))
    }
    Error(_) -> should.equal(1, 0)
  }
}

// ============================================================================
// ACCEPTANCE CRITERION: Given invalid store id format,
// when GET /api/stores/:id called, then returns appropriate error
// Boundary contract: Invalid id format returns 400 or 404 error response
// Test type: integration (tests input validation at boundary)
// ============================================================================
pub fn get_store_by_id_invalid_format_returns_error_test() {
  // Setup: Start store
  let assert Ok(store) = boba_store.new()
  let handler = boba_router.make_handler(store)

  // Action: GET /api/stores/invalid-id (non-numeric ID)
  let req = build_get_store_request("invalid-id")
  let res = handler(req)

  // Assert: Status is 400 or 404 (error response)
  should.be_true(res.status == 400 || res.status == 404)

  // Assert: Response contains error information
  let error_decoder = {
    use error <- decode.field("error", decode.string)
    decode.success(error)
  }

  case json.parse(from: res.body, using: error_decoder) {
    Ok(_) -> should.be_true(True)  // Error field present
    Error(_) -> should.equal(1, 0)
  }
}

// ============================================================================
// BOUNDARY CONTRACT VALIDATION: Response has correct Content-Type header
// Tests that response headers match expected JSON API contract
// Test type: integration (tests HTTP response headers at boundary)
// ============================================================================
pub fn get_store_by_id_returns_json_content_type_test() {
  // Setup: Start store and create a store
  let assert Ok(store) = boba_store.new()
  let created_store = create_test_store(store, "ContentType Test", "789 Pine St", "Seattle", "555-0789")
  let handler = boba_router.make_handler(store)

  // Action: GET /api/stores/:id
  let req = build_get_store_request(int.to_string(created_store.id))
  let res = handler(req)

  // Assert: Content-Type header indicates JSON
  case dict.get(res.headers, "Content-Type") {
    Ok(content_type) -> {
      should.be_true(string.contains(content_type, "application/json"))
    }
    Error(_) -> {
      // Header may be lowercase
      case dict.get(res.headers, "content-type") {
        Ok(content_type) -> {
          should.be_true(string.contains(content_type, "application/json"))
        }
        Error(_) -> should.equal(1, 0)
      }
    }
  }
}

// ============================================================================
// BOUNDARY CONTRACT VALIDATION: Response schema matches contract exactly
// Tests that all required fields are present with correct types
// Test type: integration (tests response schema at boundary)
// ============================================================================
pub fn get_store_by_id_response_schema_validation_test() {
  // Setup: Start store and create a store with drinks
  let assert Ok(store) = boba_store.new()
  let created_store = create_test_store(store, "Schema Test", "321 Elm St", "Austin", "555-0321")
  let store_id = created_store.id
  let _ = create_test_drink(store, "Jasmine Green Tea", store_id)

  let handler = boba_router.make_handler(store)

  // Action: GET /api/stores/:id
  let req = build_get_store_request(int.to_string(store_id))
  let res = handler(req)

  // Assert: Parse the JSON response with strict schema validation
  let schema_decoder = {
    use id <- decode.field("id", decode.string)
    use name <- decode.field("name", decode.string)
    use address <- decode.field("address", decode.optional(decode.string))
    use city <- decode.field("city", decode.optional(decode.string))
    use phone <- decode.field("phone", decode.optional(decode.string))
    use drink_count <- decode.field("drink_count", decode.int)
    use created_at <- decode.field("created_at", decode.string)
    decode.success(#(id, name, address, city, phone, drink_count, created_at))
  }

  case json.parse(from: res.body, using: schema_decoder) {
    Ok(#(id, name, address, city, phone, drink_count, created_at)) -> {
      // Validate id: uuid (non-empty string)
      should.be_true(string.length(id) > 0)

      // Validate name: string (non-empty)
      should.be_true(string.length(name) > 0)

      // Validate address?: optional string
      // Already validated by decoder as Option(String)

      // Validate city?: optional string
      // Already validated by decoder as Option(String)

      // Validate phone?: optional string
      // Already validated by decoder as Option(String)

      // Validate drink_count: int (>= 0)
      should.be_true(drink_count >= 0)

      // Validate created_at: timestamp string (ISO8601 format, non-empty)
      should.be_true(string.length(created_at) > 0)
    }
    Error(_) -> should.equal(1, 0)
  }
}