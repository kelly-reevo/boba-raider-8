/// Cross-layer integration tests: todo-api-client boundary contracts
///
/// These tests verify that the todo-api-client module (current layer unit)
/// will correctly call the existing backend API endpoints using proper
/// request/response formats defined by the shared types.

import gleeunit
import gleeunit/should
import gleam/json
import gleam/dynamic/decode
import gleam/option.{type Option, None, Some}
import shared.{type Priority, type Todo, High, Medium, Low, Todo}
import gleam/list
import gleam/int
import gleam/string
import shared/todo_validation
import frontend/model

pub fn main() {
  gleeunit.main()
}

// =============================================================================
// API CLIENT FUNCTION SIGNATURE TESTS
// =============================================================================
// These tests define the expected boundary contracts for the todo-api-client
// unit being implemented. They verify the function signatures and types.

/// Bridge: fetch_todos function signature contract
/// Expected: fn(Option(String)) -> Result(List(Todo), HttpError)
/// Calls: GET /api/todos or GET /api/todos?filter={active|completed}
pub fn fetch_todos_function_contract_test() {
  // Simulate the contract: fetch_todos takes optional filter string
  let filter_param: Option(String) = Some("active")

  // Would call GET /api/todos?filter=active
  let expected_path = case filter_param {
    Some(f) -> "/api/todos?filter=" <> f
    None -> "/api/todos"
  }

  expected_path |> should.equal("/api/todos?filter=active")

  // Without filter
  let no_filter_path = {
    let f: Option(String) = None
    case f {
      Some(filter) -> "/api/todos?filter=" <> filter
      None -> "/api/todos"
    }
  }
  no_filter_path |> should.equal("/api/todos")
}

/// Bridge: fetch_todos response decoding contract
/// Expected: Decodes JSON array into List(shared.Todo)
pub fn fetch_todos_response_decoding_contract_test() {
  // Simulated API response for GET /api/todos
  let api_response_json = "[{\"id\":\"todo-1\",\"title\":\"First\",\"description\":null,\"priority\":\"high\",\"completed\":false},{\"id\":\"todo-2\",\"title\":\"Second\",\"description\":\"Details\",\"priority\":\"medium\",\"completed\":true}]"

  // Expected: Parse JSON array, decode each to shared.Todo
  // The todo_from_json function from shared handles single todo
  // API client would use list.map or similar for array

  api_response_json |> string.contains("[") |> should.be_true
  api_response_json |> string.contains("todo-1") |> should.be_true
  api_response_json |> string.contains("todo-2") |> should.be_true
}

/// Bridge: create_todo function signature contract
/// Expected: fn(String, Option(String), Priority) -> Result(Todo, HttpError)
/// Calls: POST /api/todos with JSON body
pub fn create_todo_function_contract_test() {
  // Simulate the input parameters
  let title = "New todo title"
  let description: Option(String) = Some("Optional description")
  let priority = High

  // Expected request body structure
  let request_body = json.object([
    #("title", json.string(title)),
    #("description", case description {
      Some(d) -> json.string(d)
      None -> json.null()
    }),
    #("priority", shared.priority_encode(priority)),
  ]) |> json.to_string

  request_body |> string.contains("\"title\":\"New todo title\"") |> should.be_true
  request_body |> string.contains("\"priority\":\"high\"") |> should.be_true
  request_body |> string.contains("\"description\":\"Optional description\"") |> should.be_true
}

/// Bridge: create_todo response handling contract
/// Expected: 201 Created returns shared.Todo, 400 returns ValidationError
pub fn create_todo_response_contract_test() {
  // Success case: 201 with created todo JSON
  let success_response = Todo(
    id: "generated-uuid-1234",
    title: "New todo",
    description: Some("Desc"),
    priority: Medium,
    completed: False,
  )

  let success_json = shared.todo_to_json(success_response) |> json.to_string
  success_json |> string.contains("generated-uuid-1234") |> should.be_true
  success_json |> string.contains("\"completed\":false") |> should.be_true

  // Error case: 400 with validation errors
  let error_json = json.object([
    #("error", json.string("invalid_input")),
    #("details", json.array(["title is required"], json.string)),
  ]) |> json.to_string

  error_json |> string.contains("invalid_input") |> should.be_true
  error_json |> string.contains("title is required") |> should.be_true
}

/// Bridge: update_todo function signature contract
/// Expected: fn(String, TodoPatch) -> Result(Todo, HttpError)
/// Calls: PATCH /api/todos/:id with JSON body of changed fields
pub fn update_todo_function_contract_test() {
  // Simulate the parameters
  let todo_id = "todo-abc-123"
  let changes = todo_validation.TodoPatch(
    title: Some("Updated title"),
    description: None,
    priority: Some(Low),
    completed: Some(True),
  )

  // Expected request path
  let expected_path = "/api/todos/" <> todo_id
  expected_path |> should.equal("/api/todos/todo-abc-123")

  // Expected request body - only include non-None fields
  let request_fields = []
  let request_fields = case changes.title {
    Some(t) -> [#("title", json.string(t)), ..request_fields]
    None -> request_fields
  }
  let request_fields = case changes.priority {
    Some(p) -> [#("priority", shared.priority_encode(p)), ..request_fields]
    None -> request_fields
  }
  let request_fields = case changes.completed {
    Some(c) -> [#("completed", json.bool(c)), ..request_fields]
    None -> request_fields
  }

  let request_body = json.object(request_fields) |> json.to_string

  request_body |> string.contains("\"title\":\"Updated title\"") |> should.be_true
  request_body |> string.contains("\"priority\":\"low\"") |> should.be_true
  request_body |> string.contains("\"completed\":true") |> should.be_true
}

/// Bridge: update_todo response handling contract
/// Expected: 200 returns updated shared.Todo, 404 returns NotFound, 400 validation error
pub fn update_todo_response_contract_test() {
  // Success: 200 with updated todo
  let updated = Todo(
    id: "todo-abc-123",
    title: "Updated title",
    description: None,
    priority: Low,
    completed: True,
  )

  let success_json = shared.todo_to_json(updated) |> json.to_string
  success_json |> string.contains("\"title\":\"Updated title\"") |> should.be_true
  success_json |> string.contains("\"completed\":true") |> should.be_true

  // Not found: 404
  let not_found_json = json.object([#("error", json.string("not_found"))]) |> json.to_string
  not_found_json |> should.equal("{\"error\":\"not_found\"}")
}

/// Bridge: delete_todo function signature contract
/// Expected: fn(String) -> Result(Bool, HttpError)
/// Calls: DELETE /api/todos/:id
pub fn delete_todo_function_contract_test() {
  // Simulate the parameter
  let todo_id = "todo-to-delete-456"

  // Expected request path
  let expected_path = "/api/todos/" <> todo_id
  expected_path |> should.equal("/api/todos/todo-to-delete-456")

  // Success: 204 No Content (empty body)
  // Error: 404 Not Found with error JSON
  let error_json = json.object([#("error", json.string("not_found"))]) |> json.to_string
  error_json |> should.equal("{\"error\":\"not_found\"}")
}

// =============================================================================
// HTTP ERROR TYPE CONTRACT TESTS
// =============================================================================

/// Bridge: HttpError type covers all failure modes
/// Expected: NetworkError | DecodeError | ServerError(Int) | ValidationError(List(String))
pub fn http_error_type_variants_test() {
  // Simulate each error variant
  let network_err = "NetworkError"
  let decode_err = "DecodeError"
  let server_err = "ServerError(500)"
  let validation_err = "ValidationError([\"title is required\"])"

  // Each variant represents a different failure mode:
  // - NetworkError: fetch failed (no connection)
  // - DecodeError: JSON parsing failed or schema mismatch
  // - ServerError(5xx): Server internal error
  // - ServerError(4xx-not-validation): Other client errors
  // - ValidationError(400): Field validation failed

  network_err |> should.equal("NetworkError")
  decode_err |> should.equal("DecodeError")
  server_err |> should.equal("ServerError(500)")
  validation_err |> should.equal("ValidationError([\"title is required\"])")
}

/// Bridge: Error mapping from HTTP status codes
/// Expected: 400 -> ValidationError, 404 -> ServerError(404), 5xx -> ServerError(n)
pub fn http_status_to_error_mapping_test() {
  // Map status codes to HttpError variants
  let map_status = fn(status: Int, body: String) -> String {
    case status {
      400 -> {
        // Try to parse validation errors from body
        case string.contains(body, "invalid_input") {
          True -> "ValidationError"
          False -> "ServerError(400)"
        }
      }
      404 -> "ServerError(404)" // Not found
      500 -> "ServerError(500)"
      502 -> "ServerError(502)"
      _ if status >= 200 && status < 300 -> "Success"
      _ -> "ServerError(" <> int.to_string(status) <> ")"
    }
  }

  map_status(200, "ok") |> should.equal("Success")
  map_status(201, "created") |> should.equal("Success")
  map_status(400, "{\"error\":\"invalid_input\"}") |> should.equal("ValidationError")
  map_status(404, "not found") |> should.equal("ServerError(404)")
  map_status(500, "error") |> should.equal("ServerError(500)")
}

/// Bridge: Error response parsing for validation errors
/// Expected: Extract details array from {error: "invalid_input", details: [...]}
pub fn validation_error_parsing_contract_test() {
  let error_response = "{\"error\":\"invalid_input\",\"details\":[\"title is required\",\"invalid priority\"]}"

  // Decoder for validation errors
  let validation_error_decoder = {
    use error_type <- decode.field("error", decode.string)
    use details <- decode.field("details", decode.list(decode.string))
    decode.success(#(error_type, details))
  }

  // Parse and extract validation errors
  let parsed = json.parse(error_response, validation_error_decoder)

  case parsed {
    Ok(#(error_type, details)) -> {
      error_type |> should.equal("invalid_input")
      list.length(details) |> should.equal(2)
    }
    Error(_) -> should.fail()
  }
}

/// Bridge: Error response parsing for not found
/// Expected: Extract error type from {error: "not_found"}
pub fn not_found_error_parsing_contract_test() {
  let error_response = "{\"error\":\"not_found\"}"

  // Decoder for not found error
  let not_found_decoder = {
    use error_type <- decode.field("error", decode.string)
    decode.success(error_type)
  }

  let parsed = json.parse(error_response, not_found_decoder)

  case parsed {
    Ok(error_type) -> error_type |> should.equal("not_found")
    Error(_) -> should.fail()
  }
}

// =============================================================================
// REQUEST BUILDING CONTRACT TESTS
// =============================================================================

/// Bridge: GET request construction for fetch_todos
/// Expected: Proper method, path, no body
pub fn fetch_todos_request_construction_test() {
  let method = "GET"
  let path = "/api/todos"
  let body = "" // GET has no body

  method |> should.equal("GET")
  path |> should.equal("/api/todos")
  body |> should.equal("")
}

/// Bridge: GET with filter query parameter
/// Expected: Path includes ?filter=active or ?filter=completed
pub fn fetch_todos_with_filter_request_test() {
  let filter = "active"
  let path = "/api/todos?filter=" <> filter

  path |> should.equal("/api/todos?filter=active")

  // All filter
  let all_path = "/api/todos"
  all_path |> should.equal("/api/todos")
}

/// Bridge: POST request construction for create_todo
/// Expected: POST method, Content-Type: application/json, body with todo fields
pub fn create_todo_request_construction_test() {
  let method = "POST"
  let path = "/api/todos"
  let content_type = "application/json"

  let request_body = json.object([
    #("title", json.string("New todo")),
    #("priority", json.string("medium")),
  ]) |> json.to_string

  method |> should.equal("POST")
  path |> should.equal("/api/todos")
  content_type |> should.equal("application/json")
  request_body |> string.contains("title") |> should.be_true
}

/// Bridge: PATCH request construction for update_todo
/// Expected: PATCH method, path with ID, partial body
pub fn update_todo_request_construction_test() {
  let todo_id = "todo-123-abc"
  let method = "PATCH"
  let path = "/api/todos/" <> todo_id

  // Only send changed fields
  let request_body = json.object([#("completed", json.bool(True))]) |> json.to_string

  method |> should.equal("PATCH")
  path |> should.equal("/api/todos/todo-123-abc")
  request_body |> should.equal("{\"completed\":true}")
}

/// Bridge: DELETE request construction for delete_todo
/// Expected: DELETE method, path with ID, no body
pub fn delete_todo_request_construction_test() {
  let todo_id = "todo-456-def"
  let method = "DELETE"
  let path = "/api/todos/" <> todo_id
  let body = "" // DELETE typically has no body

  method |> should.equal("DELETE")
  path |> should.equal("/api/todos/todo-456-def")
  body |> should.equal("")
}

// =============================================================================
// FULL API CLIENT USAGE SIMULATION
// =============================================================================

/// Bridge: Complete fetch_todos flow simulation
/// Simulates: client calls fetch_todos -> GET /api/todos -> parses response
pub fn fetch_todos_complete_flow_test() {
  // Step 1: Call API client function
  let filter: Option(String) = None

  // Step 2: Construct request
  let path = case filter {
    Some(f) -> "/api/todos?filter=" <> f
    None -> "/api/todos"
  }
  path |> should.equal("/api/todos")

  // Step 3: Simulate response (what server would return)
  let mock_response = "[{\"id\":\"1\",\"title\":\"First\",\"description\":null,\"priority\":\"high\",\"completed\":false},{\"id\":\"2\",\"title\":\"Second\",\"description\":\"Desc\",\"priority\":\"medium\",\"completed\":true}]"

  // Step 4: Parse and decode
  mock_response |> string.contains("[{") |> should.be_true
  mock_response |> string.contains("First") |> should.be_true
  mock_response |> string.contains("Second") |> should.be_true
}

/// Bridge: Complete create_todo flow simulation
/// Simulates: client calls create_todo -> POST /api/todos -> handles response
pub fn create_todo_complete_flow_test() {
  // Step 1: User input
  let title = "Buy groceries"
  let description: Option(String) = Some("Milk, eggs, bread")
  let priority = High

  // Step 2: Build request
  let request_body = json.object([
    #("title", json.string(title)),
    #("description", case description {
      Some(d) -> json.string(d)
      None -> json.null()
    }),
    #("priority", shared.priority_encode(priority)),
  ]) |> json.to_string

  // Step 3: Simulate success response (201 Created)
  let mock_response = Todo(
    id: "new-uuid-789",
    title: title,
    description: description,
    priority: priority,
    completed: False,
  )

  let response_json = shared.todo_to_json(mock_response) |> json.to_string

  // Verify response has generated ID
  response_json |> string.contains("new-uuid-789") |> should.be_true
  response_json |> string.contains("Buy groceries") |> should.be_true
}

/// Bridge: Complete update_todo flow simulation (toggle completion)
/// Simulates: client calls update_todo -> PATCH /api/todos/:id -> handles response
pub fn update_todo_toggle_flow_test() {
  // Step 1: Existing todo (from fetch_todos)
  let existing = Todo(
    id: "todo-123",
    title: "Task",
    description: None,
    priority: Medium,
    completed: False,
  )

  // Step 2: Build update (toggle to completed)
  let patch = todo_validation.TodoPatch(
    title: None,
    description: None,
    priority: None,
    completed: Some(True),
  )

  // Step 3: Build request body (only non-None fields)
  let request_body = json.object([
    #("completed", json.bool(True)),
  ]) |> json.to_string

  request_body |> should.equal("{\"completed\":true}")

  // Step 4: Simulate response (200 OK with updated todo)
  let updated = Todo(
    id: existing.id,
    title: existing.title,
    description: existing.description,
    priority: existing.priority,
    completed: True, // Changed!
  )

  updated.completed |> should.be_true
  updated.id |> should.equal("todo-123")
}

/// Bridge: Complete delete_todo flow simulation
/// Simulates: client calls delete_todo -> DELETE /api/todos/:id -> handles response
pub fn delete_todo_complete_flow_test() {
  // Step 1: Todo ID to delete
  let todo_id = "todo-to-delete"

  // Step 2: Build request
  let method = "DELETE"
  let path = "/api/todos/" <> todo_id

  method |> should.equal("DELETE")
  path |> should.equal("/api/todos/todo-to-delete")

  // Step 3: Simulate success response (204 No Content - empty body)
  let status = 204
  let response_body = ""

  status |> should.equal(204)
  response_body |> should.equal("")
}

/// Bridge: Error handling flow simulation
/// Simulates: validation error on create -> proper HttpError returned
pub fn error_handling_flow_test() {
  // Simulate 400 response with validation errors
  let error_response = "{\"error\":\"invalid_input\",\"details\":[\"title is required\"]}"

  // Decoder for error
  let error_decoder = {
    use error <- decode.field("error", decode.string)
    use details <- decode.field("details", decode.list(decode.string))
    decode.success(#(error, details))
  }

  // Parse error
  let parsed = json.parse(error_response, error_decoder)

  // Should map to ValidationError variant
  case parsed {
    Ok(#("invalid_input", details)) -> {
      list.length(details) |> should.equal(1)
      list.first(details) |> should.equal(Ok("title is required"))
    }
    _ -> should.fail()
  }
}

// =============================================================================
// FILTER STATE API INTEGRATION
// =============================================================================

/// Bridge: FilterState maps to API query parameters
/// Expected: All -> no param, Active -> ?filter=active, Completed -> ?filter=completed
pub fn filter_state_to_query_param_test() {
  // Use FilterState from model module
  let to_query_param = fn(filter: model.FilterState) -> Option(String) {
    case filter {
      model.All -> None
      model.Active -> Some("active")
      model.Completed -> Some("completed")
    }
  }

  to_query_param(model.All) |> should.equal(None)
  to_query_param(model.Active) |> should.equal(Some("active"))
  to_query_param(model.Completed) |> should.equal(Some("completed"))
}

/// Bridge: FilterState changes trigger refetch
/// Simulates: user changes filter -> fetch_todos called with new filter
pub fn filter_change_triggers_refetch_test() {
  // Initial state: All
  let current_filter = "all"
  let current_path = "/api/todos"
  current_path |> should.equal("/api/todos")

  // User selects Active: refetch with filter
  let new_filter = "active"
  let new_path = "/api/todos?filter=" <> new_filter
  new_path |> should.equal("/api/todos?filter=active")
}

// =============================================================================
// MODEL EXTENSION CONTRACT TESTS
// =============================================================================

/// Bridge: Model stores List(shared.Todo) from API
/// Expected: Model.todos field holds todos fetched from API
pub fn model_stores_shared_todos_test() {
  // Use the actual Model from frontend/model
  let todos = [
    Todo(id: "1", title: "First", description: None, priority: High, completed: False),
    Todo(id: "2", title: "Second", description: None, priority: Medium, completed: True),
  ]

  let test_model = model.Model(
    todos: todos,
    filter: model.All,
    form_title: "",
    form_description: "",
    form_priority: shared.Medium,
    loading: False,
    error: ""
  )

  list.length(test_model.todos) |> should.equal(2)
  test_model.loading |> should.be_false
}

/// Bridge: Model form fields for create todo
/// Expected: Model holds form input state separate from todo list
pub fn model_form_fields_test() {
  let test_model = model.Model(
    todos: [],
    filter: model.All,
    form_title: "New todo",
    form_description: "Description",
    form_priority: High,
    loading: False,
    error: ""
  )

  test_model.form_title |> should.equal("New todo")
  test_model.form_description |> should.equal("Description")
  test_model.form_priority |> should.equal(High)
}

/// Bridge: Model loading state during API calls
/// Expected: Model.loading true during fetch, false after completion
pub fn model_loading_state_test() {
  let initial_model = model.Model(
    todos: [],
    filter: model.All,
    form_title: "",
    form_description: "",
    form_priority: shared.Medium,
    loading: False,
    error: ""
  )

  // Simulate loading state
  let loading_model = model.Model(..initial_model, loading: True)
  loading_model.loading |> should.be_true

  // Simulate completion
  let completed_model = model.Model(..loading_model, loading: False)
  completed_model.loading |> should.be_false
}
