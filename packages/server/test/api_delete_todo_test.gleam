import gleam/dict
import gleeunit
import gleeunit/should
import todo_actor
import todo_store
import web/router
import web/server

pub fn main() {
  gleeunit.main()
}

// Test: DELETE /api/todos/:id returns 204 with no body when todo exists
pub fn delete_existing_todo_returns_204_test() {
  // Arrange: Start actor and create a todo
  let assert Ok(actor_pid) = todo_actor.start()
  let assert Ok(created) = todo_actor.create(actor_pid, "Todo to delete", "", "medium")
  let todo_id = created.id
  let store = todo_store.TodoStore(actor_pid)

  // Act: Delete the todo via router
  let request = server.Request(method: "DELETE", path: "/api/todos/" <> todo_id, headers: dict.new(), body: "")
  let response = router.make_handler(store)(request)

  // Assert: Should return 204 with no body
  response.status |> should.equal(204)
  response.body |> should.equal("")

  // Cleanup
  todo_actor.shutdown(actor_pid)
}

// Test: DELETE /api/todos/:id returns 404 for non-existent todo
pub fn delete_nonexistent_todo_returns_404_test() {
  // Arrange: Start actor with empty state
  let assert Ok(actor_pid) = todo_actor.start()
  let non_existent_id = "00000000-0000-0000-0000-000000000000"
  let store = todo_store.TodoStore(actor_pid)

  // Act: Try to delete non-existent todo
  let request = server.Request(method: "DELETE", path: "/api/todos/" <> non_existent_id, headers: dict.new(), body: "")
  let response = router.make_handler(store)(request)

  // Assert: Should return 404 with correct error message
  response.status |> should.equal(404)
  response.body |> should.equal("{\"error\":\"Todo not found\"}")

  // Cleanup
  todo_actor.shutdown(actor_pid)
}

// Test: DELETE /api/todos/:id with malformed id returns 404
pub fn delete_malformed_id_returns_404_test() {
  // Arrange: Start actor
  let assert Ok(actor_pid) = todo_actor.start()
  let malformed_id = "not-a-valid-uuid"
  let store = todo_store.TodoStore(actor_pid)

  // Act: Try to delete with malformed id
  let request = server.Request(method: "DELETE", path: "/api/todos/" <> malformed_id, headers: dict.new(), body: "")
  let response = router.make_handler(store)(request)

  // Assert: Should return 404 (malformed IDs are treated as not found)
  response.status |> should.equal(404)
  response.body |> should.equal("{\"error\":\"Todo not found\"}")

  // Cleanup
  todo_actor.shutdown(actor_pid)
}

// Test: DELETE /api/todos/:id response headers include correct content-type for 404
pub fn delete_response_has_correct_headers_test() {
  // Arrange: Start actor
  let assert Ok(actor_pid) = todo_actor.start()
  let non_existent_id = "00000000-0000-0000-0000-000000000000"
  let store = todo_store.TodoStore(actor_pid)

  // Act: Delete request
  let request = server.Request(method: "DELETE", path: "/api/todos/" <> non_existent_id, headers: dict.new(), body: "")
  let response = router.make_handler(store)(request)

  // Assert: Status is 404 and body is valid JSON error
  response.status |> should.equal(404)
  response.body |> should.equal("{\"error\":\"Todo not found\"}")

  // Cleanup
  todo_actor.shutdown(actor_pid)
}

// Test: DELETE to non-API path returns generic not found
pub fn delete_non_api_path_returns_not_found_test() {
  // Arrange: Start actor
  let assert Ok(actor_pid) = todo_actor.start()
  let store = todo_store.TodoStore(actor_pid)

  // Act: Delete request to non-API path
  let request = server.Request(method: "DELETE", path: "/some/other/path", headers: dict.new(), body: "")
  let response = router.make_handler(store)(request)

  // Assert: Should return generic 404
  response.status |> should.equal(404)
  response.body |> should.equal("{\"error\":\"Not found\"}")

  // Cleanup
  todo_actor.shutdown(actor_pid)
}
