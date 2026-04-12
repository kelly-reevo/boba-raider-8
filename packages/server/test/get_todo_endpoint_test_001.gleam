import gleeunit/should
import gleam/dict
import gleam/json
import gleam/list
import gleam/string
import web/router
import web/server.{Request}

// Helper to extract string field from JSON
fn extract_string_field(json_str: String, key: String) -> String {
  let pattern = "\"" <> key <> "\":\""
  case string.split(json_str, pattern) {
    [_, rest] | [_, rest, ..] -> {
      case string.split(rest, "\"") {
        [val, ..] -> val
        _ -> ""
      }
    }
    _ -> ""
  }
}

// Test: GET /api/todos/:id returns 404 for non-existent todo ID
pub fn get_nonexistent_todo_returns_404_test() {
  // Arrange: Use a valid UUID format that doesn't exist
  let non_existent_id = "550e8400-e29b-41d4-a716-446655440999"

  // Act: GET the non-existent todo
  let req = Request(
    method: "GET",
    path: "/api/todos/" <> non_existent_id,
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

  // Assert: Error body contains 'error' field with message 'Todo not found'
  let error_message = extract_string_field(body_str, "error")
  error_message |> should.equal("Todo not found")
}
