import gleeunit/should
import gleam/dict
import gleam/list
import gleam/string
import web/router
import web/server.{Request}

// Test: GET /api/todos/:id returns 404 for invalid UUID format
pub fn get_invalid_uuid_format_returns_404_test() {
  // Arrange: Use invalid UUID formats
  let invalid_ids = [
    "not-a-uuid",
    "12345",
    "",
    "too-short",
    "invalid-uuid-format-with-extra-chars",
  ]

  // Act & Assert: Each invalid ID should return 404
  list.each(invalid_ids, fn(invalid_id) {
    let req = Request(
      method: "GET",
      path: "/api/todos/" <> invalid_id,
      headers: dict.new(),
      body: "",
    )

    let resp = router.handle_request(req)
    let body_str = resp.body

    // Assert: Status 404
    resp.status |> should.equal(404)

    // Assert: Content-Type is application/json
    let headers = dict.to_list(resp.headers)
    should.be_true(list.any(headers, fn(h) {
      h.0 == "Content-Type" && string.contains(h.1, "application/json")
    }))

    // Assert: Body is non-empty
    should.be_true(string.length(body_str) > 0)
  })
}
