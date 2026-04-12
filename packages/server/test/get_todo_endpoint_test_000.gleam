import gleeunit/should
import gleam/dict
import gleam/json
import gleam/string
import gleam/option.{Some}
import gleam/list
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

// Helper to extract optional string field from JSON
fn extract_optional_string(json_str: String, key: String) -> option.Option(String) {
  let pattern = "\"" <> key <> "\":"
  case string.split(json_str, pattern) {
    [_, rest] | [_, rest, ..] -> {
      let trimmed = string.trim_start(rest)
      case trimmed {
        "null" <> _ -> option.None
        "\"" <> rest2 -> {
          case string.split(rest2, "\"") {
            [val, ..] -> Some(val)
            _ -> option.None
          }
        }
        _ -> option.None
      }
    }
    _ -> option.None
  }
}

// Helper to extract bool field from JSON
fn extract_bool_field(json_str: String, key: String) -> Bool {
  let pattern = "\"" <> key <> "\":"
  case string.split(json_str, pattern) {
    [_, rest] | [_, rest, ..] -> {
      let trimmed = string.trim_start(rest)
      case string.starts_with(trimmed, "false") {
        True -> False
        False -> True
      }
    }
    _ -> False
  }
}

// Test: GET /api/todos/:id returns 200 with valid todo for existing ID
pub fn get_existing_todo_returns_200_test() {
  // Arrange: Create a todo first to have an existing ID
  let create_body = json.object([
    #("title", json.string("Test Todo")),
    #("description", json.string("Test description")),
    #("priority", json.string("medium")),
  ])

  let create_req = Request(
    method: "POST",
    path: "/api/todos",
    headers: dict.from_list([#("content-type", "application/json")]),
    body: json.to_string(create_body),
  )

  // Execute create to get an ID
  let create_response = router.handle_request(create_req)
  let create_body_str = create_response.body

  // Extract ID from creation response
  let todo_id = extract_string_field(create_body_str, "id")
  should.be_true(string.length(todo_id) > 0)

  // Act: GET the todo by ID
  let get_req = Request(
    method: "GET",
    path: "/api/todos/" <> todo_id,
    headers: dict.new(),
    body: "",
  )

  let get_response = router.handle_request(get_req)
  let get_body_str = get_response.body

  // Assert: Status 200
  get_response.status |> should.equal(200)

  // Assert: Response headers include content-type application/json
  let headers = dict.to_list(get_response.headers)
  should.be_true(list.any(headers, fn(h) {
    h.0 == "Content-Type" && string.contains(h.1, "application/json")
  }))

  // Assert: Response body contains title
  let title_val = extract_string_field(get_body_str, "title")
  title_val |> should.equal("Test Todo")

  // Assert: Response body contains description
  let desc_val = extract_optional_string(get_body_str, "description")
  desc_val |> should.equal(Some("Test description"))

  // Assert: Response body contains priority
  let priority_val = extract_string_field(get_body_str, "priority")
  priority_val |> should.equal("medium")

  // Assert: completed is false
  let completed_val = extract_bool_field(get_body_str, "completed")
  completed_val |> should.be_false()

  // Assert: id matches
  let id_from_response = extract_string_field(get_body_str, "id")
  id_from_response |> should.equal(todo_id)
}
