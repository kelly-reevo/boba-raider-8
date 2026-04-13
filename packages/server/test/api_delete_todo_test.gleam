// Integration tests for DELETE /api/todos/:id endpoint
// Tests the external HTTP API boundary contract for deleting todos

import gleeunit/should
import gleam/json
import gleam/dict
import gleam/string
import gleam/dynamic/decode
import todo_store
import web/router
import web/server.{type Request, type Response, Request}

// Helper: Create a test todo to get an existing ID
fn create_test_todo(store) {
  let assert Ok(item) = todo_store.create_todo(store, "Test Todo", "Description")
  item
}

// Helper: Build a DELETE request to /api/todos/:id
fn build_delete_request(id: String) -> Request {
  Request(
    method: "DELETE",
    path: "/api/todos/" <> id,
    headers: dict.from_list([#("accept", "application/json")]),
    body: "",
  )
}

// Helper: Build a GET request to /api/todos/:id
fn build_get_request(id: String) -> Request {
  Request(
    method: "GET",
    path: "/api/todos/" <> id,
    headers: dict.from_list([#("accept", "application/json")]),
    body: "",
  )
}

// Helper: Extract error message from error response JSON
fn decode_error_response(json_string: String) -> String {
  let decoder = {
    use error <- decode.field("error", decode.string)
    decode.success(error)
  }

  case json.parse(from: json_string, using: decoder) {
    Ok(msg) -> msg
    Error(_) -> "Unknown error"
  }
}

// Test: Given existing id, when DELETE /api/todos/:id, then 204 no content
// Test type: integration (tests HTTP API boundary contract)
// Acceptance criterion: Given existing id, when DELETE /api/todos/:id, then 204 no content
pub fn delete_existing_todo_returns_204_test() {
  // Setup: Start store and create a todo
  let assert Ok(store) = todo_store.start()
  let existing = create_test_todo(store)
  let id = existing.id
  let handler = router.make_handler(store)

  // Action: DELETE the todo
  let req = build_delete_request(id)
  let res = handler(req)

  // Assert: Status is 204
  res.status |> should.equal(204)

  // Assert: Response body is empty (no content)
  res.body |> should.equal("")
}

// Test: Given non-existent id, when DELETE /api/todos/:id, then 404
// Test type: integration (tests HTTP API boundary contract for error case)
// Acceptance criterion: Given non-existent id, when DELETE /api/todos/:id, then 404
pub fn delete_nonexistent_todo_returns_404_test() {
  // Setup: Start store (no todos created)
  let assert Ok(store) = todo_store.start()
  let fake_id = "00000000-0000-0000-0000-000000000000"
  let handler = router.make_handler(store)

  // Action: DELETE non-existent todo
  let req = build_delete_request(fake_id)
  let res = handler(req)

  // Assert: Status is 404
  res.status |> should.equal(404)

  // Assert: Response contains error message per boundary contract
  let error_msg = decode_error_response(res.body)
  error_msg |> should.equal("Todo not found")
}

// Test: Given existing id, when DELETE, then todo is removed from store and subsequent GET returns 404
// Test type: integration (tests state mutation and subsequent read at API boundary)
// Acceptance criterion: Given existing id, when DELETE, then todo is removed from store and subsequent GET returns 404
pub fn delete_removes_todo_from_store_test() {
  // Setup: Start store and create a todo
  let assert Ok(store) = todo_store.start()
  let existing = create_test_todo(store)
  let id = existing.id
  let handler = router.make_handler(store)

  // Verify: Todo exists before deletion (via GET)
  let get_req = build_get_request(id)
  let get_res_before = handler(get_req)
  get_res_before.status |> should.equal(200)

  // Action: DELETE the todo
  let delete_req = build_delete_request(id)
  let delete_res = handler(delete_req)

  // Assert: DELETE returns 204
  delete_res.status |> should.equal(204)

  // Verify: Subsequent GET returns 404 (todo no longer exists)
  let get_res_after = handler(get_req)
  get_res_after.status |> should.equal(404)

  // Assert: GET error response contains appropriate message
  let error_msg = decode_error_response(get_res_after.body)
  should.be_true(string.contains(error_msg, "not found") || string.contains(error_msg, "Not found"))
}

// Test: Verify that deleting one todo does not affect other todos
// Test type: integration (tests isolation of delete operation at boundary)
pub fn delete_isolates_to_target_todo_test() {
  // Setup: Start store and create multiple todos
  let assert Ok(store) = todo_store.start()
  let todo1 = create_test_todo(store)
  let todo2 = create_test_todo(store)
  let todo3 = create_test_todo(store)
  let handler = router.make_handler(store)

  // Action: DELETE only todo2
  let delete_req = build_delete_request(todo2.id)
  let delete_res = handler(delete_req)

  // Assert: DELETE succeeds
  delete_res.status |> should.equal(204)

  // Verify: todo1 still exists (GET returns 200)
  let get_todo1 = handler(build_get_request(todo1.id))
  get_todo1.status |> should.equal(200)

  // Verify: todo2 no longer exists (GET returns 404)
  let get_todo2 = handler(build_get_request(todo2.id))
  get_todo2.status |> should.equal(404)

  // Verify: todo3 still exists (GET returns 200)
  let get_todo3 = handler(build_get_request(todo3.id))
  get_todo3.status |> should.equal(200)
}

// Test: Verify that deleting an already-deleted todo returns 404
// Test type: integration (tests idempotency edge case at boundary)
pub fn delete_already_deleted_todo_returns_404_test() {
  // Setup: Start store and create a todo
  let assert Ok(store) = todo_store.start()
  let existing = create_test_todo(store)
  let id = existing.id
  let handler = router.make_handler(store)

  // Action: DELETE the todo (first time)
  let req = build_delete_request(id)
  let res1 = handler(req)
  res1.status |> should.equal(204)

  // Action: DELETE the same todo again (second time)
  let res2 = handler(req)

  // Assert: Second DELETE returns 404
  res2.status |> should.equal(404)

  // Assert: Error message per boundary contract
  let error_msg = decode_error_response(res2.body)
  error_msg |> should.equal("Todo not found")
}
