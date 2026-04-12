import gleeunit
import gleeunit/should
import gleam/dict
import gleam/dynamic/decode
import gleam/json.{type DecodeError}
import gleam/option.{None, Some}
import gleam/string
import shared.{type Todo}
import todo_store
import web/handlers/todo_handler
import web/server

pub fn main() {
  gleeunit.main()
}

// Test helper to create a store
fn create_store() {
  let assert Ok(store) = todo_store.start()
  store
}

// Test helper to make a request
fn make_request(body: String) -> server.Request {
  server.Request(
    method: "POST",
    path: "/api/todos",
    headers: dict.from_list([#("content-type", "application/json")]),
    body: body,
  )
}

// Test helper to decode a Todo from JSON response
fn decode_todo_response(json_str: String) -> Result(Todo, DecodeError) {
  let description_decoder = decode.optional(decode.string)

  let priority_decoder = decode.string |> decode.then(fn(str) {
    case str {
      "low" -> decode.success(shared.Low)
      "high" -> decode.success(shared.High)
      _ -> decode.success(shared.Medium)
    }
  })

  let decoder = {
    use id <- decode.field("id", decode.string)
    use title <- decode.field("title", decode.string)
    use description <- decode.field("description", description_decoder)
    use priority <- decode.field("priority", priority_decoder)
    use completed <- decode.field("completed", decode.bool)
    use created_at <- decode.field("created_at", decode.string)
    use updated_at <- decode.field("updated_at", decode.string)

    decode.success(shared.Todo(
      id: id,
      title: title,
      description: description,
      priority: priority,
      completed: completed,
      created_at: created_at,
      updated_at: updated_at,
    ))
  }

  json.parse(json_str, decoder)
}

// Test helper to check if string is valid UUID format
fn is_valid_uuid(id: String) -> Bool {
  // Basic check - UUID should be non-empty and contain dashes
  string.length(id) > 0 && string.contains(id, "-")
}

// Test helper to check if string is valid ISO8601 timestamp
fn is_valid_timestamp(ts: String) -> Bool {
  // Basic check - should contain T and end with Z
  string.contains(ts, "T") && string.ends_with(ts, "Z")
}

pub fn create_todo_with_title_only_returns_201_test() {
  let store = create_store()
  let request_body =
    json.object([#("title", json.string("Buy groceries"))])
    |> json.to_string()

  let request = make_request(request_body)
  let response = todo_handler.create(request, store)

  // Assert status is 201
  response.status |> should.equal(201)

  // Check content-type header
  let content_type = dict.get(response.headers, "Content-Type")
  content_type |> should.equal(Ok("application/json"))

  // Verify response body is valid JSON with expected fields
  let result = decode_todo_response(response.body)
  let assert Ok(todo_item) = result

  // Verify all required fields
  is_valid_uuid(todo_item.id) |> should.be_true()
  todo_item.title |> should.equal("Buy groceries")
  todo_item.description |> should.equal(None)
  todo_item.priority |> should.equal(shared.Medium)
  todo_item.completed |> should.equal(False)
  is_valid_timestamp(todo_item.created_at) |> should.be_true()
  is_valid_timestamp(todo_item.updated_at) |> should.be_true()
}

pub fn create_todo_with_all_fields_returns_201_with_provided_values_test() {
  let store = create_store()
  let request_body =
    json.object([
      #("title", json.string("Finish project")),
      #("description", json.string("Complete the Gleam API implementation")),
      #("priority", json.string("high")),
    ])
    |> json.to_string()

  let request = make_request(request_body)
  let response = todo_handler.create(request, store)

  // Assert status is 201
  response.status |> should.equal(201)

  // Verify response contains provided values
  let result = decode_todo_response(response.body)
  let assert Ok(todo_item) = result

  todo_item.title |> should.equal("Finish project")
  todo_item.description |> should.equal(Some("Complete the Gleam API implementation"))
  todo_item.priority |> should.equal(shared.High)
  todo_item.completed |> should.equal(False)
}

pub fn create_todo_with_low_priority_returns_201_test() {
  let store = create_store()
  let request_body =
    json.object([
      #("title", json.string("Low priority task")),
      #("priority", json.string("low")),
    ])
    |> json.to_string()

  let request = make_request(request_body)
  let response = todo_handler.create(request, store)

  // Assert status is 201
  response.status |> should.equal(201)

  // Verify response contains low priority
  let result = decode_todo_response(response.body)
  let assert Ok(todo_item) = result

  todo_item.priority |> should.equal(shared.Low)
}

pub fn create_todo_without_title_returns_422_test() {
  let store = create_store()
  let request_body =
    json.object([#("description", json.string("Missing title field"))])
    |> json.to_string()

  let request = make_request(request_body)
  let response = todo_handler.create(request, store)

  // Assert status is 422
  response.status |> should.equal(422)

  // Verify error response structure
  response.body |> string.contains("errors") |> should.be_true()
  response.body |> string.contains("title") |> should.be_true()
}

pub fn create_todo_with_empty_title_returns_422_test() {
  let store = create_store()
  let request_body =
    json.object([
      #("title", json.string("")),
      #("description", json.string("Has empty title")),
    ])
    |> json.to_string()

  let request = make_request(request_body)
  let response = todo_handler.create(request, store)

  // Assert status is 422
  response.status |> should.equal(422)

  // Verify error response contains field error for title
  response.body |> string.contains("errors") |> should.be_true()
}

pub fn create_todo_with_invalid_priority_returns_422_test() {
  let store = create_store()
  let request_body =
    json.object([
      #("title", json.string("Valid title")),
      #("priority", json.string("invalid_value")),
    ])
    |> json.to_string()

  let request = make_request(request_body)
  let response = todo_handler.create(request, store)

  // Assert status is 422
  response.status |> should.equal(422)

  // Verify error response contains field error for priority
  response.body |> string.contains("errors") |> should.be_true()
  response.body |> string.contains("priority") |> should.be_true()
}

pub fn create_todo_with_title_too_long_returns_422_test() {
  let store = create_store()
  let long_title = string.repeat("a", 201)
  let request_body =
    json.object([#("title", json.string(long_title))])
    |> json.to_string()

  let request = make_request(request_body)
  let response = todo_handler.create(request, store)

  // Assert status is 422
  response.status |> should.equal(422)

  // Verify error response contains field error for title length
  response.body |> string.contains("errors") |> should.be_true()
  response.body |> string.contains("title") |> should.be_true()
  response.body |> string.contains("200") |> should.be_true()
}

pub fn create_todo_with_whitespace_title_gets_trimmed_test() {
  let store = create_store()
  let request_body =
    json.object([#("title", json.string("  Buy groceries  "))])
    |> json.to_string()

  let request = make_request(request_body)
  let response = todo_handler.create(request, store)

  // Assert status is 201
  response.status |> should.equal(201)

  // Verify title was trimmed
  let result = decode_todo_response(response.body)
  let assert Ok(todo_item) = result

  todo_item.title |> should.equal("Buy groceries")
}

pub fn create_todo_with_description_saves_correctly_test() {
  let store = create_store()
  let request_body =
    json.object([
      #("title", json.string("Task with description")),
      #("description", json.string("This is a detailed description")),
    ])
    |> json.to_string()

  let request = make_request(request_body)
  let response = todo_handler.create(request, store)

  // Assert status is 201
  response.status |> should.equal(201)

  // Verify description is saved
  let result = decode_todo_response(response.body)
  let assert Ok(todo_item) = result

  todo_item.description |> should.equal(Some("This is a detailed description"))
}

pub fn create_todo_with_null_description_returns_null_test() {
  let store = create_store()
  let request_body =
    json.object([
      #("title", json.string("Task with null description")),
      #("description", json.null()),
    ])
    |> json.to_string()

  let request = make_request(request_body)
  let response = todo_handler.create(request, store)

  // Assert status is 201
  response.status |> should.equal(201)

  // Verify description is None
  let result = decode_todo_response(response.body)
  let assert Ok(todo_item) = result

  todo_item.description |> should.equal(None)
}
