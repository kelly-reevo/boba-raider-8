import gleeunit
import gleeunit/should
import gleam/string
import todo_store
import web/router
import web/server.{Request}
import gleam/dict

pub fn main() {
  gleeunit.main()
}

// Test GET /api/todos/:id returns 404 for non-existent ID
pub fn get_todo_returns_404_for_non_existent_id_test() {
  let store = todo_store.start()
  let assert Ok(s) = store

  let handler = router.make_handler(s)
  let request = Request(
    method: "GET",
    path: "/api/todos/non-existent-123",
    headers: dict.new(),
    body: "",
  )

  let response = handler(request)

  response.status |> should.equal(404)
  string.contains(response.body, "Todo not found") |> should.be_true()
}

// Test GET /api/todos/:id returns 200 with todo when exists
pub fn get_todo_returns_200_with_existing_todo_test() {
  let store = todo_store.start()
  let assert Ok(s) = store

  // Create a todo first
  let payload = [
    #("title", "Test Todo"),
    #("description", "Test Description"),
    #("priority", "high"),
  ]
  let result = todo_store.create_api(s, payload)

  let id = case result {
    todo_store.CreateOkResult(item) -> item.id
    _ -> ""
  }

  let handler = router.make_handler(s)
  let request = Request(
    method: "GET",
    path: "/api/todos/" <> id,
    headers: dict.new(),
    body: "",
  )

  let response = handler(request)

  response.status |> should.equal(200)
  string.contains(response.body, "Test Todo") |> should.be_true()
  string.contains(response.body, id) |> should.be_true()
  string.contains(response.body, "high") |> should.be_true()
}

// Test GET /api/todos/:id returns 404 for empty ID
pub fn get_todo_returns_404_for_empty_id_test() {
  let store = todo_store.start()
  let assert Ok(s) = store

  let handler = router.make_handler(s)
  let request = Request(
    method: "GET",
    path: "/api/todos/",
    headers: dict.new(),
    body: "",
  )

  let response = handler(request)

  response.status |> should.equal(404)
}

// Test GET /api/todos/:id returns correct JSON structure
pub fn get_todo_returns_correct_json_structure_test() {
  let store = todo_store.start()
  let assert Ok(s) = store

  // Create a todo
  let payload = [
    #("title", "Structure Test"),
    #("description", "Testing JSON structure"),
    #("priority", "medium"),
  ]
  let result = todo_store.create_api(s, payload)

  let id = case result {
    todo_store.CreateOkResult(item) -> item.id
    _ -> ""
  }

  let handler = router.make_handler(s)
  let request = Request(
    method: "GET",
    path: "/api/todos/" <> id,
    headers: dict.new(),
    body: "",
  )

  let response = handler(request)

  response.status |> should.equal(200)
  // Check all required fields are present
  string.contains(response.body, "\"id\"") |> should.be_true()
  string.contains(response.body, "\"title\"") |> should.be_true()
  string.contains(response.body, "\"description\"") |> should.be_true()
  string.contains(response.body, "\"priority\"") |> should.be_true()
  string.contains(response.body, "\"completed\"") |> should.be_true()
  string.contains(response.body, "\"created_at\"") |> should.be_true()
  // Check priority value
  string.contains(response.body, "\"medium\"") |> should.be_true()
  // Check completed is boolean
  string.contains(response.body, "false") |> should.be_true()
}
