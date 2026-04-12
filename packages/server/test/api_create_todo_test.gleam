// Integration tests for POST /api/todos endpoint
// Tests validation, creation, and error handling

import gleeunit/should
import gleam/json
import gleam/dict
import gleam/option.{None, Some}
import gleam/string
import gleam/dynamic/decode
import shared.{type Todo, Low, Medium, High}
import todo_store
import web/router
import web/server.{type Request, type Response}

// Helper: Build a POST request to /api/todos with JSON body
fn build_post_request(body: String) -> server.Request {
  server.Request(
    method: "POST",
    path: "/api/todos",
    headers: dict.from_list([#("content-type", "application/json")]),
    body: body,
  )
}

// Helper: Decode a Todo from JSON response
fn decode_todo_response(json_string: String) -> Result(Todo, String) {
  let decoder = {
    use id <- decode.field("id", decode.string)
    use title <- decode.field("title", decode.string)
    use description <- decode.field("description", decode.optional(decode.string))
    use priority_str <- decode.field("priority", decode.string)
    use completed <- decode.field("completed", decode.bool)
    use created_at <- decode.field("created_at", decode.string)
    use updated_at <- decode.field("updated_at", decode.string)

    decode.success(#(id, title, description, priority_str, completed, created_at, updated_at))
  }

  case json.parse(from: json_string, using: decoder) {
    Ok(#(id, title, description, priority_str, completed, created_at, updated_at)) -> {
      case priority_str {
        "low" -> Ok(shared.Todo(id, title, description, Low, completed, created_at, updated_at))
        "medium" -> Ok(shared.Todo(id, title, description, Medium, completed, created_at, updated_at))
        "high" -> Ok(shared.Todo(id, title, description, High, completed, created_at, updated_at))
        _ -> Error("Invalid priority in response: " <> priority_str)
      }
    }
    Error(_) -> Error("Failed to decode todo from: " <> json_string)
  }
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

// Helper: Check if string looks like a UUID (contains dashes and alphanumeric)
fn is_valid_uuid(id: String) -> Bool {
  string.length(id) == 36 && string.contains(id, "-")
}

// Test: Valid todo with title returns 201 with created todo
pub fn post_todo_with_valid_title_returns_201_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  let post_body = json.object([
    #("title", json.string("Buy groceries")),
  ]) |> json.to_string()

  let req = build_post_request(post_body)
  let res = handler(req)

  res.status |> should.equal(201)

  let assert Ok(created) = decode_todo_response(res.body)
  is_valid_uuid(created.id) |> should.be_true()
  created.title |> should.equal("Buy groceries")
  created.completed |> should.be_false()
  { string.length(created.created_at) > 0 } |> should.be_true()
  { string.length(created.updated_at) > 0 } |> should.be_true()
}

// Test: Valid todo with all fields returns 201
pub fn post_todo_with_all_fields_returns_201_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  let post_body = json.object([
    #("title", json.string("Complete project")),
    #("description", json.string("Finish the API implementation")),
    #("priority", json.string("high")),
    #("completed", json.bool(False)),
  ]) |> json.to_string()

  let req = build_post_request(post_body)
  let res = handler(req)

  res.status |> should.equal(201)

  let assert Ok(created) = decode_todo_response(res.body)
  created.title |> should.equal("Complete project")
  created.description |> should.equal(Some("Finish the API implementation"))
}

// Test: Todo with title and description returns 201
pub fn post_todo_with_title_and_description_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  let post_body = json.object([
    #("title", json.string("Call mom")),
    #("description", json.string("Don't forget to ask about the recipe")),
  ]) |> json.to_string()

  let req = build_post_request(post_body)
  let res = handler(req)

  res.status |> should.equal(201)

  let assert Ok(created) = decode_todo_response(res.body)
  created.title |> should.equal("Call mom")
  created.description |> should.equal(Some("Don't forget to ask about the recipe"))
  created.completed |> should.be_false()
}

// Test: Missing title returns 422
pub fn post_todo_without_title_returns_422_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  let post_body = json.object([]) |> json.to_string()

  let req = build_post_request(post_body)
  let res = handler(req)

  should.be_true(res.status == 400 || res.status == 422)

  let error_msg = decode_error_response(res.body)
  should.be_true(string.contains(error_msg, "Title") || string.contains(error_msg, "title"))
}

// Test: Empty title returns 422
pub fn post_todo_with_empty_title_returns_422_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  let post_body = json.object([
    #("title", json.string("")),
  ]) |> json.to_string()

  let req = build_post_request(post_body)
  let res = handler(req)

  should.be_true(res.status == 400 || res.status == 422)

  let error_msg = decode_error_response(res.body)
  should.be_true(string.contains(error_msg, "Title") || string.contains(error_msg, "title"))
}

// Test: Whitespace-only title returns 422
pub fn post_todo_with_whitespace_title_returns_422_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  let post_body = json.object([
    #("title", json.string("   ")),
  ]) |> json.to_string()

  let req = build_post_request(post_body)
  let res = handler(req)

  should.be_true(res.status == 400 || res.status == 422)

  let error_msg = decode_error_response(res.body)
  should.be_true(string.contains(error_msg, "Title") || string.contains(error_msg, "title"))
}

// Test: Null title returns 422
pub fn post_todo_with_null_title_returns_422_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  let post_body = "{\"title\": null}"

  let req = build_post_request(post_body)
  let res = handler(req)

  should.be_true(res.status == 400 || res.status == 422)
}

// Helper: Generate a string of specified length
fn generate_long_string(length: Int) -> String {
  string.repeat("a", length)
}

// Test: Title over 200 chars returns 422
pub fn post_todo_with_title_over_200_chars_returns_422_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  let long_title = generate_long_string(201)
  let post_body = json.object([
    #("title", json.string(long_title)),
  ]) |> json.to_string()

  let req = build_post_request(post_body)
  let res = handler(req)

  should.be_true(res.status == 400 || res.status == 422)

  let error_msg = decode_error_response(res.body)
  should.be_true(string.contains(error_msg, "Title") || string.contains(error_msg, "title") || string.contains(error_msg, "length") || string.contains(error_msg, "200"))
}

// Test: Title exactly 200 chars returns 201
pub fn post_todo_with_title_exactly_200_chars_returns_201_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  let exact_title = generate_long_string(200)
  let post_body = json.object([
    #("title", json.string(exact_title)),
  ]) |> json.to_string()

  let req = build_post_request(post_body)
  let res = handler(req)

  res.status |> should.equal(201)
}

// Test: Title 199 chars returns 201
pub fn post_todo_with_title_199_chars_returns_201_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  let near_limit_title = generate_long_string(199)
  let post_body = json.object([
    #("title", json.string(near_limit_title)),
  ]) |> json.to_string()

  let req = build_post_request(post_body)
  let res = handler(req)

  res.status |> should.equal(201)
}

// Test: Invalid priority returns 422
pub fn post_todo_with_invalid_priority_returns_422_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  let post_body = json.object([
    #("title", json.string("Test todo")),
    #("priority", json.string("urgent")),
  ]) |> json.to_string()

  let req = build_post_request(post_body)
  let res = handler(req)

  should.be_true(res.status == 400 || res.status == 422)

  let error_msg = decode_error_response(res.body)
  let contains_priority_reference = string.contains(error_msg, "priority") ||
    string.contains(error_msg, "low") ||
    string.contains(error_msg, "medium") ||
    string.contains(error_msg, "high") ||
    string.contains(error_msg, "Priority")
  should.be_true(contains_priority_reference)
}

// Test: Valid low priority returns 201
pub fn post_todo_with_low_priority_returns_201_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  let post_body = json.object([
    #("title", json.string("Low priority task")),
    #("priority", json.string("low")),
  ]) |> json.to_string()

  let req = build_post_request(post_body)
  let res = handler(req)

  res.status |> should.equal(201)
}

// Test: Valid medium priority returns 201
pub fn post_todo_with_medium_priority_returns_201_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  let post_body = json.object([
    #("title", json.string("Medium priority task")),
    #("priority", json.string("medium")),
  ]) |> json.to_string()

  let req = build_post_request(post_body)
  let res = handler(req)

  res.status |> should.equal(201)
}

// Test: Valid high priority returns 201
pub fn post_todo_with_high_priority_returns_201_test() {
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  let post_body = json.object([
    #("title", json.string("High priority task")),
    #("priority", json.string("high")),
  ]) |> json.to_string()

  let req = build_post_request(post_body)
  let res = handler(req)

  res.status |> should.equal(201)
}
