// Integration test for POST /api/drinks endpoint - validation errors
// Tests the external HTTP API boundary contract for validation error responses

import gleeunit/should
import gleam/json
import gleam/dict
import gleam/list
import gleam/string
import gleam/dynamic/decode
import boba_store
import shared/boba_validation.{StoreInput}
import web/boba_router
import web/server.{type Request, request}

// Helper: Build a POST request to /api/drinks with JSON body
fn build_post_request(body: String) -> Request {
  request(
    method: "POST",
    path: "/api/drinks",
    headers: dict.from_list([
      #("accept", "application/json"),
      #("content-type", "application/json"),
    ]),
    body: body,
  )
}

// Helper: Create a test store via the store API to get a valid store_id
fn create_test_store(store) {
  let assert Ok(s) = boba_store.create_store(store, StoreInput(
    name: "Test Boba Shop",
    address: dict.new(),
    phone: dict.new(),
  ))
  s
}

// Helper: Decode validation errors array from 422 response
fn decode_validation_errors(json_string: String) -> List(#(String, String)) {
  let field_error_decoder = {
    use field <- decode.field("field", decode.string)
    use message <- decode.field("message", decode.string)
    decode.success(#(field, message))
  }

  let decoder = {
    use errors <- decode.field("errors", decode.list(field_error_decoder))
    decode.success(errors)
  }

  case json.parse(from: json_string, using: decoder) {
    Ok(errors) -> errors
    Error(_) -> []
  }
}

// Helper: Decode error field
fn decode_error_field(json_string: String) -> String {
  let decoder = {
    use error <- decode.field("error", decode.string)
    decode.success(error)
  }

  case json.parse(from: json_string, using: decoder) {
    Ok(err) -> err
    Error(_) -> ""
  }
}

// Test: Given empty name, when POST /api/drinks, then returns 422 with name validation error
// Test type: integration (tests validation at HTTP API boundary)
// Acceptance criterion: Given invalid drink data, then returns 422 with validation errors
pub fn create_drink_empty_name_returns_422_test() {
  // Setup: Start store and create a store
  let assert Ok(store) = boba_store.new()
  let test_store = create_test_store(store)
  let handler = boba_router.make_handler(store)

  // Build drink payload with empty name (invalid per boundary contract)
  let payload = json.to_string(json.object([
    #("store_id", json.int(test_store.id)),
    #("name", json.string("")),
  ]))

  // Action: POST /api/drinks
  let req = build_post_request(payload)
  let res = handler(req)

  // Assert: Status is 422
  res.status |> should.equal(422)

  // Assert: Response contains validation errors array
  let errors = decode_validation_errors(res.body)
  should.be_true(list.length(errors) > 0)

  // Assert: Error indicates name field validation failure
  let error_fields = list.map(errors, fn(e) { e.0 })
  should.be_true(list.any(error_fields, fn(f) { f == "name" }))
}

// Test: Given name too short, when POST /api/drinks, then returns 422 with name length error
// Test type: integration (tests validation at HTTP API boundary)
// Acceptance criterion: Given invalid drink data, then returns 422 with validation errors
pub fn create_drink_short_name_returns_422_test() {
  // Setup: Start store and create a store
  let assert Ok(store) = boba_store.new()
  let test_store = create_test_store(store)
  let handler = boba_router.make_handler(store)

  // Build drink payload with 1-character name (below minimum length)
  let payload = json.to_string(json.object([
    #("store_id", json.int(test_store.id)),
    #("name", json.string("A")),
  ]))

  // Action: POST /api/drinks
  let req = build_post_request(payload)
  let res = handler(req)

  // Assert: Status is 422
  res.status |> should.equal(422)

  // Assert: Response contains validation errors
  let errors = decode_validation_errors(res.body)
  should.be_true(list.length(errors) > 0)
}

// Test: Given missing store_id, when POST /api/drinks, then returns 422 with store_id validation error
// Test type: integration (tests validation at HTTP API boundary)
// Acceptance criterion: Given invalid drink data, then returns 422 with validation errors
pub fn create_drink_missing_store_id_returns_422_test() {
  // Setup: Start store
  let assert Ok(store) = boba_store.new()
  let handler = boba_router.make_handler(store)

  // Build drink payload without store_id field
  let payload = json.to_string(json.object([
    #("name", json.string("Milk Tea")),
  ]))

  // Action: POST /api/drinks
  let req = build_post_request(payload)
  let res = handler(req)

  // Assert: Status is 422 (validation error for missing required field)
  res.status |> should.equal(422)

  // Assert: Response contains validation errors
  let errors = decode_validation_errors(res.body)
  should.be_true(list.length(errors) > 0)
}

// Test: Given negative store_id, when POST /api/drinks, then returns 422 with store_id validation error
// Test type: integration (tests validation at HTTP API boundary)
// Acceptance criterion: Given invalid drink data, then returns 422 with validation errors
pub fn create_drink_negative_store_id_returns_422_test() {
  // Setup: Start store
  let assert Ok(store) = boba_store.new()
  let handler = boba_router.make_handler(store)

  // Build drink payload with negative store_id
  let payload = json.to_string(json.object([
    #("store_id", json.int(-1)),
    #("name", json.string("Milk Tea")),
  ]))

  // Action: POST /api/drinks
  let req = build_post_request(payload)
  let res = handler(req)

  // Assert: Status is 422
  res.status |> should.equal(422)

  // Assert: Response contains validation errors
  let errors = decode_validation_errors(res.body)
  should.be_true(list.length(errors) > 0)
}

// Test: Given multiple validation errors, when POST /api/drinks, then returns 422 with all errors
// Test type: integration (tests multiple validation failures at boundary)
// Acceptance criterion: Given invalid drink data, then returns 422 with validation errors
pub fn create_drink_multiple_errors_returns_all_in_422_test() {
  // Setup: Start store
  let assert Ok(store) = boba_store.new()
  let handler = boba_router.make_handler(store)

  // Build drink payload with multiple validation failures (empty name, invalid store_id)
  let payload = json.to_string(json.object([
    #("store_id", json.int(0)),
    #("name", json.string("")),
  ]))

  // Action: POST /api/drinks
  let req = build_post_request(payload)
  let res = handler(req)

  // Assert: Status is 422
  res.status |> should.equal(422)

  // Assert: Response contains validation errors array
  let error_type = decode_error_field(res.body)
  error_type |> should.equal("Validation failed")

  // Assert: Multiple field errors present
  let errors = decode_validation_errors(res.body)
  should.be_true(list.length(errors) >= 1)
}

// Test: Verify 422 response Content-Type is application/json
// Test type: integration (tests response headers at boundary)
pub fn create_drink_422_returns_json_content_type_test() {
  // Setup: Start store
  let assert Ok(store) = boba_store.new()
  let handler = boba_router.make_handler(store)

  // Build invalid payload
  let payload = json.to_string(json.object([
    #("store_id", json.int(0)),
    #("name", json.string("X")),
  ]))

  // Action: POST /api/drinks
  let req = build_post_request(payload)
  let res = handler(req)

  // Assert: Content-Type header indicates JSON
  case dict.get(res.headers, "Content-Type") {
    Ok(content_type) -> {
      should.be_true(string.contains(content_type, "application/json"))
    }
    Error(_) -> should.fail()
  }
}
