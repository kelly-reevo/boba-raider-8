// packages/server/test/update_store_endpoint_test.gleam

import gleam/json
import gleam/dict
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import wisp
import app/web/router
import app/boba_store

pub fn main() {
  gleeunit.main()
}

// Test: Given valid update payload PUT /api/stores/:id, then returns 200 and updated store
pub fn update_store_valid_payload_returns_200_test() {
  // Arrange: Create a store first
  let store_id = "store-123"
  let initial_store = boba_store.Store(
    id: store_id,
    name: "Original Boba Shop",
    address: Some("123 Original St"),
    city: Some("Original City"),
    phone: Some("555-0000"),
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  )
  let store_state = dict.from_list([#(store_id, initial_store)])

  let update_payload = json.object([
    #("name", json.string("Updated Boba Shop")),
    #("address", json.string("456 New Address")),
    #("city", json.string("New City")),
    #("phone", json.string("555-9999")),
  ])

  let req = wisp.Request(
    method: wisp.Put,
    path: "/api/stores/" <> store_id,
    query: dict.new(),
    headers: dict.new(),
    body: wisp.TextBody(json.to_string(update_payload)),
  )

  // Act
  let response = router.handle_request(req, store_state)

  // Assert
  should.equal(response.status, 200)

  // Verify response body contains updated store fields
  let response_body = wisp.get_response_body(response)
  let response_json = wisp.decode(response_body)

  // Response should have id, name, address, city, phone, updated_at
  should.be_ok(response_json)

  let response_obj = response_json |> should.be_ok
  should.equal(wisp.field(response_obj, "id"), Some(json.string(store_id)))
  should.equal(wisp.field(response_obj, "name"), Some(json.string("Updated Boba Shop")))
  should.equal(wisp.field(response_obj, "address"), Some(json.string("456 New Address")))
  should.equal(wisp.field(response_obj, "city"), Some(json.string("New City")))
  should.equal(wisp.field(response_obj, "phone"), Some(json.string("555-9999")))
  should.not_equal(wisp.field(response_obj, "updated_at"), None)
}

// Test: Given valid partial update payload, returns 200 with merged store
pub fn update_store_partial_payload_returns_200_test() {
  // Arrange: Create a store first
  let store_id = "store-456"
  let initial_store = boba_store.Store(
    id: store_id,
    name: "Original Shop",
    address: Some("123 Original St"),
    city: Some("Original City"),
    phone: Some("555-0000"),
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  )
  let store_state = dict.from_list([#(store_id, initial_store)])

  // Partial update - only name
  let update_payload = json.object([
    #("name", json.string("Partially Updated Shop")),
  ])

  let req = wisp.Request(
    method: wisp.Put,
    path: "/api/stores/" <> store_id,
    query: dict.new(),
    headers: dict.new(),
    body: wisp.TextBody(json.to_string(update_payload)),
  )

  // Act
  let response = router.handle_request(req, store_state)

  // Assert
  should.equal(response.status, 200)

  let response_body = wisp.get_response_body(response)
  let response_json = wisp.decode(response_body) |> should.be_ok

  // Updated field should change
  should.equal(wisp.field(response_json, "name"), Some(json.string("Partially Updated Shop")))

  // Unchanged fields should retain original values
  should.equal(wisp.field(response_json, "address"), Some(json.string("123 Original St")))
  should.equal(wisp.field(response_json, "city"), Some(json.string("Original City")))
  should.equal(wisp.field(response_json, "phone"), Some(json.string("555-0000")))
}

// Test: Given non-existent store id, then returns 404
pub fn update_store_nonexistent_returns_404_test() {
  // Arrange: Empty store state (no stores exist)
  let store_state = dict.new()
  let nonexistent_id = "store-does-not-exist"

  let update_payload = json.object([
    #("name", json.string("New Name")),
  ])

  let req = wisp.Request(
    method: wisp.Put,
    path: "/api/stores/" <> nonexistent_id,
    query: dict.new(),
    headers: dict.new(),
    body: wisp.TextBody(json.to_string(update_payload)),
  )

  // Act
  let response = router.handle_request(req, store_state)

  // Assert
  should.equal(response.status, 404)

  let response_body = wisp.get_response_body(response)
  should.equal(response_body, "")
}

// Test: Given invalid payload with missing required validation, returns 422 with errors
pub fn update_store_empty_name_returns_422_test() {
  // Arrange
  let store_id = "store-789"
  let initial_store = boba_store.Store(
    id: store_id,
    name: "Original Shop",
    address: None,
    city: None,
    phone: None,
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  )
  let store_state = dict.from_list([#(store_id, initial_store)])

  // Invalid payload - empty name
  let update_payload = json.object([
    #("name", json.string("")),
  ])

  let req = wisp.Request(
    method: wisp.Put,
    path: "/api/stores/" <> store_id,
    query: dict.new(),
    headers: dict.new(),
    body: wisp.TextBody(json.to_string(update_payload)),
  )

  // Act
  let response = router.handle_request(req, store_state)

  // Assert
  should.equal(response.status, 422)

  let response_body = wisp.get_response_body(response)
  let response_json = wisp.decode(response_body) |> should.be_ok

  // Response should have errors array
  let errors = wisp.field(response_json, "errors")
  should.not_equal(errors, None)
}

// Test: Given invalid payload with too long fields, returns 422 with errors
pub fn update_store_name_too_long_returns_422_test() {
  // Arrange
  let store_id = "store-abc"
  let initial_store = boba_store.Store(
    id: store_id,
    name: "Original Shop",
    address: None,
    city: None,
    phone: None,
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  )
  let store_state = dict.from_list([#(store_id, initial_store)])

  // Invalid payload - name too long (> 255 chars)
  let long_name = string.repeat("a", 256)
  let update_payload = json.object([
    #("name", json.string(long_name)),
  ])

  let req = wisp.Request(
    method: wisp.Put,
    path: "/api/stores/" <> store_id,
    query: dict.new(),
    headers: dict.new(),
    body: wisp.TextBody(json.to_string(update_payload)),
  )

  // Act
  let response = router.handle_request(req, store_state)

  // Assert
  should.equal(response.status, 422)

  let response_body = wisp.get_response_body(response)
  let response_json = wisp.decode(response_body) |> should.be_ok

  // Response should have errors array
  let errors = wisp.field(response_json, "errors")
  should.not_equal(errors, None)
}

// Test: Given invalid phone format, returns 422 with validation errors
pub fn update_store_invalid_phone_returns_422_test() {
  // Arrange
  let store_id = "store-def"
  let initial_store = boba_store.Store(
    id: store_id,
    name: "Original Shop",
    address: None,
    city: None,
    phone: None,
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  )
  let store_state = dict.from_list([#(store_id, initial_store)])

  // Invalid payload - invalid phone format
  let update_payload = json.object([
    #("phone", json.string("not-a-valid-phone")),
  ])

  let req = wisp.Request(
    method: wisp.Put,
    path: "/api/stores/" <> store_id,
    query: dict.new(),
    headers: dict.new(),
    body: wisp.TextBody(json.to_string(update_payload)),
  )

  // Act
  let response = router.handle_request(req, store_state)

  // Assert
  should.equal(response.status, 422)

  let response_body = wisp.get_response_body(response)
  let response_json = wisp.decode(response_body) |> should.be_ok

  // Response should have errors array
  let errors = wisp.field(response_json, "errors")
  should.not_equal(errors, None)
}

// Test: Given malformed JSON payload, returns 422
pub fn update_store_malformed_json_returns_422_test() {
  // Arrange
  let store_id = "store-ghi"
  let initial_store = boba_store.Store(
    id: store_id,
    name: "Original Shop",
    address: None,
    city: None,
    phone: None,
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  )
  let store_state = dict.from_list([#(store_id, initial_store)])

  // Malformed JSON
  let invalid_json = "{name: missing quotes}"

  let req = wisp.Request(
    method: wisp.Put,
    path: "/api/stores/" <> store_id,
    query: dict.new(),
    headers: dict.new(),
    body: wisp.TextBody(invalid_json),
  )

  // Act
  let response = router.handle_request(req, store_state)

  // Assert
  should.equal(response.status, 422)
}

// Test: Given extra/unknown fields in payload, ignores them and updates valid fields
pub fn update_store_ignores_unknown_fields_test() {
  // Arrange
  let store_id = "store-jkl"
  let initial_store = boba_store.Store(
    id: store_id,
    name: "Original Shop",
    address: None,
    city: None,
    phone: None,
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  )
  let store_state = dict.from_list([#(store_id, initial_store)])

  // Payload with extra unknown fields
  let update_payload = json.object([
    #("name", json.string("Updated Shop")),
    #("unknown_field", json.string("should be ignored")),
    #("another_unknown", json.int(123)),
  ])

  let req = wisp.Request(
    method: wisp.Put,
    path: "/api/stores/" <> store_id,
    query: dict.new(),
    headers: dict.new(),
    body: wisp.TextBody(json.to_string(update_payload)),
  )

  // Act
  let response = router.handle_request(req, store_state)

  // Assert
  should.equal(response.status, 200)

  let response_body = wisp.get_response_body(response)
  let response_json = wisp.decode(response_body) |> should.be_ok

  // Valid field should be updated
  should.equal(wisp.field(response_json, "name"), Some(json.string("Updated Shop")))

  // Unknown fields should not appear in response
  should.equal(wisp.field(response_json, "unknown_field"), None)
  should.equal(wisp.field(response_json, "another_unknown"), None)
}
