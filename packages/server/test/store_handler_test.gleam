import gleeunit
import gleeunit/should
import gleam/dict
import gleam/option.{None, Some}
import gleam/string
import handlers/store_handler
import services/geocoding
import services/store_service
import shared.{decode_create_store_request}
import web/server.{Request}

pub fn main() {
  gleeunit.main()
}

// Decode request tests

pub fn decode_create_store_request_valid_test() {
  let json_body = "{\"name\": \"Boba Paradise\", \"address\": \"123 Main St\"}"

  let result = decode_create_store_request(json_body)

  case result {
    Ok(request) -> {
      request.name |> should.equal("Boba Paradise")
      request.address |> should.equal("123 Main St")
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_create_store_request_full_test() {
  let json_body = "{\"name\": \"Boba Paradise\", \"address\": \"123 Main St\", \"phone\": \"555-1234\", \"hours\": \"9AM-9PM\", \"description\": \"Best boba in town\", \"image_url\": \"http://example.com/image.jpg\"}"

  let result = decode_create_store_request(json_body)

  case result {
    Ok(request) -> {
      request.name |> should.equal("Boba Paradise")
      request.address |> should.equal("123 Main St")
      request.phone |> should.equal(Some("555-1234"))
      request.hours |> should.equal(Some("9AM-9PM"))
      request.description |> should.equal(Some("Best boba in town"))
      request.image_url |> should.equal(Some("http://example.com/image.jpg"))
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_create_store_request_missing_name_test() {
  let json_body = "{\"address\": \"123 Main St\"}"

  let result = decode_create_store_request(json_body)

  result |> should.be_error
}

pub fn decode_create_store_request_missing_address_test() {
  let json_body = "{\"name\": \"Boba Paradise\"}"

  let result = decode_create_store_request(json_body)

  result |> should.be_error
}

pub fn decode_create_store_request_empty_name_test() {
  let json_body = "{\"name\": \"\", \"address\": \"123 Main St\"}"

  let result = decode_create_store_request(json_body)

  result |> should.be_error
}

pub fn decode_create_store_request_empty_address_test() {
  let json_body = "{\"name\": \"Boba Paradise\", \"address\": \"\"}"

  let result = decode_create_store_request(json_body)

  result |> should.be_error
}

pub fn decode_create_store_request_invalid_json_test() {
  let json_body = "not valid json"

  let result = decode_create_store_request(json_body)

  result |> should.be_error
}

// Geocoding tests

pub fn geocode_address_valid_test() {
  let result = geocoding.geocode_address("123 Main St, San Francisco, CA")

  result |> should.be_ok
}

pub fn geocode_address_empty_test() {
  let result = geocoding.geocode_address("")

  result |> should.be_error
}

// Store service tests

pub fn store_service_create_and_get_test() {
  let assert Ok(actor) = store_service.start()

  let request = shared.CreateStoreRequest(
    name: "Boba Paradise",
    address: "123 Main St",
    phone: Some("555-1234"),
    hours: Some("9AM-9PM"),
    description: Some("Best boba"),
    image_url: None,
  )
  let coords = shared.Coordinates(lat: 37.7749, lng: -122.4194)

  // Create store
  let create_result = store_service.create_store(actor, request, coords, "user_123")

  create_result |> should.be_ok

  case create_result {
    Ok(store) -> {
      store.name |> should.equal("Boba Paradise")
      store.address |> should.equal("123 Main St")
      store.created_by |> should.equal("user_123")
      store.lat |> should.equal(37.7749)
      store.lng |> should.equal(-122.4194)

      // Verify we can retrieve it
      let retrieved = store_service.get_store(actor, store.id)
      let _ = should.be_ok(retrieved)
      Nil
    }
    Error(_) -> should.fail()
  }
}

pub fn store_service_duplicate_address_test() {
  let assert Ok(actor) = store_service.start()

  let request1 = shared.CreateStoreRequest(
    name: "Boba Paradise",
    address: "123 Main St",
    phone: None,
    hours: None,
    description: None,
    image_url: None,
  )
  let coords = shared.Coordinates(lat: 37.0, lng: -122.0)

  // First creation should succeed
  let result1 = store_service.create_store(actor, request1, coords, "user_1")
  result1 |> should.be_ok

  // Second creation with same address should fail
  let request2 = shared.CreateStoreRequest(
    name: "Another Boba",
    address: "123 Main St",
    phone: None,
    hours: None,
    description: None,
    image_url: None,
  )
  let result2 = store_service.create_store(actor, request2, coords, "user_2")
  result2 |> should.be_error
}

// HTTP handler integration tests

pub fn create_store_handler_success_test() {
  let assert Ok(actor) = store_service.start()

  let request = Request(
    method: "POST",
    path: "/api/stores",
    headers: dict.from_list([#("x-user-id", "test_user_123")]),
    body: "{\"name\": \"Boba Paradise\", \"address\": \"123 Main St, San Francisco, CA\"}",
  )

  let response = store_handler.create(request, actor)

  should.equal(response.status, 201)

  // Verify response body contains store JSON
  should.be_true(string.contains(response.body, "\"id\""))
  should.be_true(string.contains(response.body, "Boba Paradise"))
}

pub fn create_store_handler_missing_auth_test() {
  let assert Ok(actor) = store_service.start()

  let request = Request(
    method: "POST",
    path: "/api/stores",
    headers: dict.new(),
    body: "{\"name\": \"Boba Paradise\", \"address\": \"123 Main St\"}",
  )

  let response = store_handler.create(request, actor)

  should.equal(response.status, 401)
}

pub fn create_store_handler_invalid_json_test() {
  let assert Ok(actor) = store_service.start()

  let request = Request(
    method: "POST",
    path: "/api/stores",
    headers: dict.from_list([#("x-user-id", "test_user")]),
    body: "not valid json",
  )

  let response = store_handler.create(request, actor)

  should.equal(response.status, 422)
}

pub fn create_store_handler_missing_required_test() {
  let assert Ok(actor) = store_service.start()

  let request = Request(
    method: "POST",
    path: "/api/stores",
    headers: dict.from_list([#("x-user-id", "test_user")]),
    body: "{\"name\": \"Boba Paradise\"}",
  )

  let response = store_handler.create(request, actor)

  should.equal(response.status, 422)
}

pub fn create_store_handler_duplicate_address_test() {
  let assert Ok(actor) = store_service.start()

  // First request
  let request1 = Request(
    method: "POST",
    path: "/api/stores",
    headers: dict.from_list([#("x-user-id", "user_1")]),
    body: "{\"name\": \"First Boba\", \"address\": \"123 Main St\"}",
  )
  let response1 = store_handler.create(request1, actor)
  should.equal(response1.status, 201)

  // Second request with same address
  let request2 = Request(
    method: "POST",
    path: "/api/stores",
    headers: dict.from_list([#("x-user-id", "user_2")]),
    body: "{\"name\": \"Second Boba\", \"address\": \"123 Main St\"}",
  )
  let response2 = store_handler.create(request2, actor)
  should.equal(response2.status, 409)
}
