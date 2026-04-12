import gleam/dict
import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None, Some}
import gleeunit/should
import todo_store
import web/router
import web/server.{type Request, type Response}

// Helper to create a test request
fn make_request(method: String, path: String, body: String) -> Request {
  server.Request(
    method: method,
    path: path,
    headers: dict.new(),
    body: body,
  )
}

// Helper to get response status as string
fn get_status_string(response: Response) -> String {
  int_to_string(response.status)
}

// Helper to convert int to string
fn int_to_string(n: Int) -> String {
  case n {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    6 -> "6"
    7 -> "7"
    8 -> "8"
    9 -> "9"
    _ -> {
      let quotient = n / 10
      let remainder = n % 10
      case quotient {
        0 -> int_to_string(remainder)
        _ -> int_to_string(quotient) <> int_to_string(remainder)
      }
    }
  }
}

// Test setup - configure router with a fresh store
fn setup_router() {
  let assert Ok(store) = todo_store.start()
  let handler = router.configure(store)
  handler
}

// Type definition matching the boundary contract
type TodoResponse {
  TodoResponse(
    id: String,
    title: String,
    description: Option(String),
    completed: Bool,
  )
}

// Decoder for the todo type per boundary contract
fn todo_decoder() -> decode.Decoder(TodoResponse) {
  use id <- decode.field("id", decode.string)
  use title <- decode.field("title", decode.string)
  use description <- decode.optional_field("description", None, decode.optional(decode.string))
  use completed <- decode.field("completed", decode.bool)
  decode.success(TodoResponse(id: id, title: title, description: description, completed: completed))
}

// Error response decoder per boundary contract
fn error_decoder() -> decode.Decoder(ErrorResponse) {
  use error <- decode.field("error", decode.string)
  decode.success(ErrorResponse(error: error))
}

type ErrorResponse {
  ErrorResponse(error: String)
}

// Test: GET /api/todos/:id with valid id returns 200 and todo JSON
pub fn get_todo_valid_id_returns_200_with_todo_json_test() {
  // Arrange: Setup router with fresh store
  let handler = setup_router()

  // Create a todo first via POST to get a valid id
  let create_body = json.object([
    #("title", json.string("Test Todo")),
    #("description", json.string("Test Description")),
    #("completed", json.bool(False)),
  ]) |> json.to_string

  let create_request = make_request("POST", "/api/todos", create_body)

  // Act: Call the router/handler
  let create_response = handler(create_request)

  // Assert: Created successfully
  get_status_string(create_response) |> should.equal("201")

  // Extract the id from the create response
  let created_todo = json.parse(create_response.body, todo_decoder())
  let assert Ok(todo_data) = created_todo
  let todo_id = todo_data.id

  // Act: Now GET the todo by id
  let get_request = make_request("GET", "/api/todos/" <> todo_id, "")
  let get_response = handler(get_request)

  // Assert
  get_status_string(get_response) |> should.equal("200")

  let fetched_todo = json.parse(get_response.body, todo_decoder())

  // Verify the response structure matches boundary contract
  let assert Ok(t) = fetched_todo
  t.id |> should.equal(todo_id)
  t.title |> should.equal("Test Todo")
  t.description |> should.equal(option.Some("Test Description"))
  t.completed |> should.equal(False)
}

// Test: GET /api/todos/:id with non-existent id returns 404 with error message
pub fn get_todo_nonexistent_id_returns_404_with_error_message_test() {
  // Arrange: Setup router with fresh store
  let handler = setup_router()

  // Use a uuid that definitely doesn't exist
  let non_existent_id = "00000000-0000-0000-0000-000000000000"

  // Act
  let request = make_request("GET", "/api/todos/" <> non_existent_id, "")
  let response = handler(request)

  // Assert: Status is 404
  get_status_string(response) |> should.equal("404")

  // Assert: Body contains error message per boundary contract
  let decoded = json.parse(response.body, error_decoder())

  let assert Ok(err) = decoded
  err.error |> should.equal("todo not found")
}

// Test: GET /api/todos/:id with invalid id format returns 404
pub fn get_todo_invalid_id_format_returns_404_test() {
  // Arrange: Setup router with fresh store
  let handler = setup_router()

  // Test various invalid id formats
  let invalid_ids = ["not-a-uuid", "123", "abc-def", "", "special!@#"]

  // Act & Assert for each invalid id
  list_each(invalid_ids, fn(invalid_id) {
    let request = make_request("GET", "/api/todos/" <> invalid_id, "")
    let response = handler(request)

    // Assert: Always returns 404 for any invalid/non-existent id
    get_status_string(response) |> should.equal("404")

    // Assert: Body contains error message per boundary contract
    let decoded = json.parse(response.body, error_decoder())

    let assert Ok(err) = decoded
    err.error |> should.equal("todo not found")
  })
}

// Test: GET response has correct content-type header
pub fn get_todo_returns_json_content_type_test() {
  // Arrange: Setup router with fresh store
  let handler = setup_router()

  // First create a todo
  let create_body = json.object([
    #("title", json.string("Content Type Test")),
    #("completed", json.bool(False)),
  ]) |> json.to_string

  let create_request = make_request("POST", "/api/todos", create_body)
  let create_response = handler(create_request)

  // Extract the id
  let created_todo = json.parse(create_response.body, todo_decoder())
  let assert Ok(todo_data) = created_todo
  let todo_id = todo_data.id

  // Act: GET the todo
  let get_request = make_request("GET", "/api/todos/" <> todo_id, "")
  let get_response = handler(get_request)

  // Assert: Content-Type is application/json
  let content_type = dict.get(get_response.headers, "Content-Type")
  content_type |> should.equal(Ok("application/json"))
}

// Test: GET 404 response also has correct content-type header
pub fn get_todo_404_returns_json_content_type_test() {
  // Arrange: Setup router with fresh store
  let handler = setup_router()

  // Act: Request non-existent todo
  let request = make_request("GET", "/api/todos/non-existent-id", "")
  let response = handler(request)

  // Assert: Even 404s should have JSON content-type
  let content_type = dict.get(response.headers, "Content-Type")
  content_type |> should.equal(Ok("application/json"))
}

// Simple list.each implementation
fn list_each(list: List(a), f: fn(a) -> b) {
  case list {
    [] -> Nil
    [x, ..xs] -> {
      f(x)
      list_each(xs, f)
    }
  }
}
