// Integration test for POST /api/drinks endpoint - happy path
// Tests the external HTTP API boundary contract for creating drinks

import gleeunit/should
import gleam/json
import gleam/dict
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

// Helper: Decode a drink response from JSON
fn decode_drink_response(json_string: String) -> #(Int, Int, String, String) {
  let decoder = {
    use id <- decode.field("id", decode.int)
    use store_id <- decode.field("store_id", decode.int)
    use name <- decode.field("name", decode.string)
    use created_at <- decode.field("created_at", decode.string)
    decode.success(#(id, store_id, name, created_at))
  }

  case json.parse(from: json_string, using: decoder) {
    Ok(result) -> result
    Error(_) -> #(-1, -1, "parse_error", "")
  }
}

// Test: Given valid drink payload, when POST /api/drinks, then returns 201 with created drink
// Test type: integration (tests HTTP API boundary contract)
// Acceptance criterion: Given valid drink payload POST /api/drinks, then returns 201 with created drink
pub fn create_drink_valid_payload_returns_201_test() {
  // Setup: Start store and create a store to get valid store_id
  let assert Ok(store) = boba_store.new()
  let test_store = create_test_store(store)
  let handler = boba_router.make_handler(store)

  // Build valid drink payload per boundary contract
  let payload = json.to_string(json.object([
    #("store_id", json.int(test_store.id)),
    #("name", json.string("Milk Tea with Boba")),
  ]))

  // Action: POST /api/drinks
  let req = build_post_request(payload)
  let res = handler(req)

  // Assert: Status is 201
  res.status |> should.equal(201)

  // Assert: Response body contains created drink per boundary contract
  let #(id, store_id, name, created_at) = decode_drink_response(res.body)

  // id: positive integer assigned by server
  should.be_true(id > 0)

  // store_id: matches the request
  store_id |> should.equal(test_store.id)

  // name: matches the request
  name |> should.equal("Milk Tea with Boba")

  // created_at: non-empty ISO timestamp
  should.be_true(string.length(created_at) > 0)
}
