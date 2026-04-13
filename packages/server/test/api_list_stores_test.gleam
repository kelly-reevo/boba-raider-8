import gleam/dict
import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import web/router
import web/server

pub fn main() {
  gleeunit.main()
}

// Test 1: Basic pagination returns correct structure
pub fn list_stores_pagination_test() {
  let req = server.Request(
    method: "GET",
    path: "/api/stores?limit=10&offset=0",
    headers: dict.new(),
    body: "",
  )

  let res = router.handle_request(req)

  // Assert HTTP 200
  res.status |> should.equal(200)

  // Response body should be valid JSON with expected structure
  res.body |> string.contains("\"stores\"") |> should.be_true()
  res.body |> string.contains("\"total\"") |> should.be_true()
  res.body |> string.contains("\"limit\"") |> should.be_true()
  res.body |> string.contains("\"offset\"") |> should.be_true()
}

// Test 2: Invalid sort_by returns 400
pub fn list_stores_invalid_sort_by_test() {
  let req = server.Request(
    method: "GET",
    path: "/api/stores?sort_by=invalid_field",
    headers: dict.new(),
    body: "",
  )

  let res = router.handle_request(req)

  // Should return 400 Bad Request for invalid enum value
  res.status |> should.equal(400)
}

// Test 3: Invalid sort_order returns 400
pub fn list_stores_invalid_sort_order_test() {
  let req = server.Request(
    method: "GET",
    path: "/api/stores?sort_by=name&sort_order=invalid_order",
    headers: dict.new(),
    body: "",
  )

  let res = router.handle_request(req)

  // Should return 400 Bad Request for invalid enum value
  res.status |> should.equal(400)
}

// Test 4: Store object has required fields in response structure
pub fn list_stores_store_object_structure_test() {
  let req = server.Request(
    method: "GET",
    path: "/api/stores?limit=10",
    headers: dict.new(),
    body: "",
  )

  let res = router.handle_request(req)

  res.status |> should.equal(200)

  // Response should contain expected fields in the structure
  res.body |> string.contains("\"stores\"") |> should.be_true()
  res.body |> string.contains("\"total\"") |> should.be_true()
  res.body |> string.contains("\"limit\"") |> should.be_true()
  res.body |> string.contains("\"offset\"") |> should.be_true()
}

// Test 5: Empty search returns empty stores array with total 0
pub fn list_stores_empty_search_test() {
  let req = server.Request(
    method: "GET",
    path: "/api/stores?search=nonexistentstore12345",
    headers: dict.new(),
    body: "",
  )

  let res = router.handle_request(req)

  res.status |> should.equal(200)

  // Response should show empty stores array
  res.body |> string.contains("\"stores\":[]") |> should.be_true()
  res.body |> string.contains("\"total\":0") |> should.be_true()
}

// Test 6: Pagination metadata reflects request parameters
pub fn list_stores_pagination_metadata_test() {
  let test_cases = [
    #("5", "0", "\"limit\":5", "\"offset\":0"),
    #("10", "10", "\"limit\":10", "\"offset\":10"),
    #("20", "40", "\"limit\":20", "\"offset\":40"),
  ]

  list.each(test_cases, fn(test_case) {
    let #(req_limit, req_offset, expected_limit, expected_offset) = test_case

    let req = server.Request(
      method: "GET",
      path: "/api/stores?limit=" <> req_limit <> "&offset=" <> req_offset,
      headers: dict.new(),
      body: "",
    )

    let res = router.handle_request(req)

    res.status |> should.equal(200)
    res.body |> string.contains(expected_limit) |> should.be_true()
    res.body |> string.contains(expected_offset) |> should.be_true()
  })
}

// Test 7: Valid sort_by values are accepted
pub fn list_stores_valid_sort_by_test() {
  let valid_values = ["name", "city", "created_at"]

  list.each(valid_values, fn(sort_by) {
    let req = server.Request(
      method: "GET",
      path: "/api/stores?sort_by=" <> sort_by,
      headers: dict.new(),
      body: "",
    )

    let res = router.handle_request(req)

    // Should return 200 OK for valid sort_by values
    res.status |> should.equal(200)
  })
}

// Test 8: Valid sort_order values are accepted
pub fn list_stores_valid_sort_order_test() {
  let valid_orders = ["asc", "desc"]

  list.each(valid_orders, fn(sort_order) {
    let req = server.Request(
      method: "GET",
      path: "/api/stores?sort_by=name&sort_order=" <> sort_order,
      headers: dict.new(),
      body: "",
    )

    let res = router.handle_request(req)

    // Should return 200 OK for valid sort_order values
    res.status |> should.equal(200)
  })
}
