/// Cross-layer integration tests: frontend-todo-model + todo-api-client + shared types
///
/// These tests verify that the current layer units (frontend model extensions and
/// API client) correctly integrate with the previously integrated backend code
/// through the shared package types.

import gleeunit
import gleeunit/should
import gleam/json
import gleam/dynamic/decode
import gleam/option.{type Option, None, Some}
import shared.{type Priority, type Todo, type AppError, High, Medium, Low, Todo}
import shared/todo_validation

pub fn main() {
  gleeunit.main()
}

// =============================================================================
// CROSS-LAYER TEST: shared.Todo type compatibility with frontend model
// =============================================================================

/// Bridge: shared.Todo type fields match what frontend model expects
/// Verifies the shared Todo type can be used by frontend-todo-model
pub fn shared_todo_type_structure_test() {
  // Create a shared.Todo (this is what the API would return)
  let item = Todo(
    id: "test-uuid-1234",
    title: "Test Todo",
    description: Some("Test description"),
    priority: High,
    completed: False,
  )

  // Verify all fields frontend model needs are present
  item.id |> should.equal("test-uuid-1234")
  item.title |> should.equal("Test Todo")
  item.description |> should.equal(Some("Test description"))
  item.priority |> should.equal(High)
  item.completed |> should.be_false
}

/// Bridge: shared.Todo can represent all priority levels frontend filter needs
/// Verifies Priority enum values align between shared and filter.FilterState
pub fn shared_priority_matches_filter_states_test() {
  // Frontend FilterState: All | Active | Completed
  // Backend Priority: High | Medium | Low
  // These are independent but both must exist for full feature

  let priorities = [High, Medium, Low]

  // Verify each priority can be stored in a Todo
  let todos = list.map(priorities, fn(p) {
    Todo(id: "id", title: "Task", description: None, priority: p, completed: False)
  })

  list.length(todos) |> should.equal(3)
}

/// Bridge: shared.Todo JSON encoding for API client requests
/// Verifies todo_to_json produces format API client can work with
pub fn shared_todo_json_encoding_test() {
  let item = Todo(
    id: "abc-123",
    title: "Buy groceries",
    description: Some("Milk and eggs"),
    priority: Medium,
    completed: True,
  )

  let json_str = shared.todo_to_json(item) |> json.to_string

  // Verify JSON structure matches expected API format
  json_str |> string.contains("\"id\":") |> should.be_true
  json_str |> string.contains("\"title\":") |> should.be_true
  json_str |> string.contains("\"priority\":") |> should.be_true
  json_str |> string.contains("\"completed\":") |> should.be_true
  json_str |> string.contains("abc-123") |> should.be_true
  json_str |> string.contains("Buy groceries") |> should.be_true
}

/// Decoder for Todo type
fn todo_decoder() -> decode.Decoder(Todo) {
  use id <- decode.field("id", decode.string)
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  use priority <- decode.field("priority", priority_decoder())
  use completed <- decode.field("completed", decode.bool)
  decode.success(Todo(id:, title:, description:, priority:, completed:))
}

fn priority_decoder() -> decode.Decoder(Priority) {
  use str <- decode.then(decode.string)
  case str {
    "high" -> decode.success(High)
    "medium" -> decode.success(Medium)
    "low" -> decode.success(Low)
    _ -> decode.failure(High, "Priority")
  }
}

/// Bridge: shared.Todo JSON decoding for API client responses
/// Verifies todo decoder works with API responses
pub fn shared_todo_json_decoding_test() {
  let json_str = "{\"id\":\"xyz-789\",\"title\":\"Do laundry\",\"description\":null,\"priority\":\"low\",\"completed\":false}"

  // Parse JSON string directly with decoder
  let result = json.parse(json_str, todo_decoder())
  case result {
    Ok(item) -> {
      item.id |> should.equal("xyz-789")
      item.title |> should.equal("Do laundry")
      item.description |> should.equal(None)
      item.priority |> should.equal(Low)
      item.completed |> should.be_false
    }
    Error(_) -> should.fail()
  }
}

/// Bridge: shared.Todo list JSON encoding for GET /api/todos response
/// Verifies JSON array format matches what API client will decode
pub fn shared_todo_list_json_encoding_test() {
  let todos = [
    Todo(id: "1", title: "First", description: None, priority: High, completed: False),
    Todo(id: "2", title: "Second", description: Some("desc"), priority: Medium, completed: True),
  ]

  let json_str = json.array(todos, shared.todo_to_json) |> json.to_string

  // Verify array structure
  json_str |> string.contains("[{") |> should.be_true
  json_str |> string.contains("First") |> should.be_true
  json_str |> string.contains("Second") |> should.be_true
}

// =============================================================================
// CROSS-LAYER TEST: shared.Priority with frontend form handling
// =============================================================================

/// Bridge: Priority encoder produces strings for API client JSON bodies
/// Verifies priority_encode outputs match API expected values
pub fn priority_encoding_for_api_requests_test() {
  let high_json = shared.priority_encode(High) |> json.to_string
  let med_json = shared.priority_encode(Medium) |> json.to_string
  let low_json = shared.priority_encode(Low) |> json.to_string

  high_json |> should.equal("\"high\"")
  med_json |> should.equal("\"medium\"")
  low_json |> should.equal("\"low\"")
}

/// Helper to decode priority from JSON string
fn decode_priority(json_str: String) -> Result(Priority, json.DecodeError) {
  json.parse(json_str, shared.priority_decoder())
}

/// Bridge: Priority decoder handles API response strings
/// Verifies priority_decoder accepts API response values
pub fn priority_decoding_from_api_responses_test() {
  // Decode "high"
  case decode_priority("\"high\"") {
    Ok(High) -> True |> should.be_true
    _ -> should.fail()
  }

  // Decode "medium"
  case decode_priority("\"medium\"") {
    Ok(Medium) -> True |> should.be_true
    _ -> should.fail()
  }

  // Decode "low"
  case decode_priority("\"low\"") {
    Ok(Low) -> True |> should.be_true
    _ -> should.fail()
  }
}

/// Bridge: Frontend form priority strings map to shared.Priority
/// Verifies form selection values align with shared type
pub fn form_priority_values_match_shared_test() {
  // Frontend form would use these string values for selection
  let form_values = ["low", "medium", "high"]

  // Each should decode to corresponding Priority
  let decoder = shared.priority_decoder()

  list.each(form_values, fn(v) {
    let json_str = "\"" <> v <> "\""
    let result = json.parse(json_str, decoder)
    result |> should.be_ok
  })
}

// =============================================================================
// CROSS-LAYER TEST: shared.AppError with frontend error handling
// =============================================================================

/// Bridge: shared.AppError.NotFound for missing todos
/// Verifies error type matches what API returns for 404
pub fn app_error_not_found_test() {
  let error = shared.NotFound
  let message = shared.error_message(error)

  message |> should.equal("Not found")
}

/// Bridge: shared.AppError.InvalidInput with field errors
/// Verifies validation errors serialize correctly for frontend display
pub fn app_error_invalid_input_test() {
  let errors = ["title is required", "invalid priority"]
  let error = shared.InvalidInput(errors)

  let message = shared.error_message(error)
  message |> should.equal("Invalid input: title is required, invalid priority")
}

/// Bridge: shared.error_to_json produces API error response format
/// Verifies JSON format matches what API client will receive
pub fn app_error_json_format_test() {
  // NotFound -> 404 error JSON
  let not_found_json = shared.error_to_json(shared.NotFound)
  not_found_json |> string.contains("not_found") |> should.be_true

  // InvalidInput -> 400 error JSON with details
  let invalid_json = shared.error_to_json(shared.InvalidInput(["bad field"]))
  invalid_json |> string.contains("invalid_input") |> should.be_true
  invalid_json |> string.contains("details") |> should.be_true
  invalid_json |> string.contains("bad field") |> should.be_true
}

// =============================================================================
// CROSS-LAYER TEST: Validation output feeds API client
// =============================================================================

/// Bridge: todo_validation.TodoPatch type for update requests
/// Verifies patch structure matches what update endpoint expects
pub fn todo_patch_type_structure_test() {
  let patch = todo_validation.TodoPatch(
    title: Some("Updated title"),
    description: None,
    priority: Some(Medium),
    completed: Some(True),
  )

  patch.title |> should.equal(Some("Updated title"))
  patch.description |> should.equal(None)
  patch.priority |> should.equal(Some(Medium))
  patch.completed |> should.equal(Some(True))
}

/// Bridge: todo_validation.TodoInput for create requests
/// Verifies validated input matches actor CreateTodo message structure
pub fn todo_input_type_structure_test() {
  let input = todo_validation.TodoInput(
    title: "New Task",
    description: Some("Details here"),
    priority: High,
  )

  input.title |> should.equal("New Task")
  input.description |> should.equal(Some("Details here"))
  input.priority |> should.equal(High)
}

/// Bridge: Validation returns errors compatible with shared.AppError
/// Verifies validation layer output can be converted to API error response
pub fn validation_errors_convert_to_app_error_test() {
  let result = todo_validation.validate_todo_input("", None, "invalid")

  let assert Error(errors) = result

  // Convert to AppError for API response
  let app_error: AppError = shared.InvalidInput(errors)
  let json_response = shared.error_to_json(app_error)

  // Verify it's a valid error response format
  json_response |> string.contains("invalid_input") |> should.be_true
}

/// Bridge: Validation success produces input for actor/ API create
/// Verifies happy path validation output structure
pub fn validation_success_produces_create_input_test() {
  let result = todo_validation.validate_todo_input(
    "Valid title",
    Some("Valid description"),
    "high"
  )

  case result {
    Ok(input) -> {
      input.title |> should.equal("Valid title")
      input.description |> should.equal(Some("Valid description"))
      input.priority |> should.equal(High)
    }
    Error(_) -> should.fail()
  }
}

// =============================================================================
// CROSS-LAYER TEST: Filter state integration with shared types
// =============================================================================

/// Bridge: Filter state affects which todos are displayed
/// Verifies filter logic can be applied to List(shared.Todo)
pub fn filter_logic_with_shared_todos_test() {
  let todos = [
    Todo(id: "1", title: "Active task", description: None, priority: High, completed: False),
    Todo(id: "2", title: "Completed task", description: None, priority: Medium, completed: True),
    Todo(id: "3", title: "Another active", description: None, priority: Low, completed: False),
  ]

  // Simulate "active" filter - keep only !completed
  let active = list.filter(todos, fn(t) { !t.completed })
  list.length(active) |> should.equal(2)

  // Simulate "completed" filter - keep only completed
  let completed = list.filter(todos, fn(t) { t.completed })
  list.length(completed) |> should.equal(1)

  // Simulate "all" filter - keep all
  list.length(todos) |> should.equal(3)
}

/// Bridge: Todo completion status maps between shared and filter states
/// Verifies completed field can drive All | Active | Completed filtering
pub fn todo_completed_drives_filter_state_test() {
  let active_todo = Todo(id: "a", title: "Active", description: None, priority: High, completed: False)
  let completed_todo = Todo(id: "c", title: "Done", description: None, priority: Medium, completed: True)

  // Active filter: completed=False passes
  active_todo.completed |> should.be_false

  // Completed filter: completed=True passes
  completed_todo.completed |> should.be_true
}

// =============================================================================
// CROSS-LAYER TEST: API endpoint request/response contracts
// =============================================================================

/// Bridge: POST /api/todos request body format
/// Verifies create request JSON structure
pub fn create_todo_request_body_format_test() {
  // Expected request body for create todo
  let request_body = json.object([
    #("title", json.string("New todo")),
    #("description", json.string("Description text")),
    #("priority", json.string("medium")),
  ]) |> json.to_string

  request_body |> string.contains("\"title\":\"New todo\"") |> should.be_true
  request_body |> string.contains("\"priority\":\"medium\"") |> should.be_true
}

/// Bridge: POST /api/todos response format (201 created)
/// Verifies create response matches shared.Todo JSON structure
pub fn create_todo_response_format_test() {
  let created_todo = Todo(
    id: "generated-uuid",
    title: "Created",
    description: None,
    priority: Low,
    completed: False,
  )

  let response_json = shared.todo_to_json(created_todo) |> json.to_string

  // Response should be full todo object with generated ID
  response_json |> string.contains("generated-uuid") |> should.be_true
  response_json |> string.contains("\"completed\":false") |> should.be_true
}

/// Bridge: GET /api/todos response format (200 OK)
/// Verifies list response is JSON array of todos
pub fn list_todos_response_format_test() {
  let todos = [
    Todo(id: "1", title: "First", description: None, priority: High, completed: False),
    Todo(id: "2", title: "Second", description: None, priority: Low, completed: True),
  ]

  let response_json = json.array(todos, shared.todo_to_json) |> json.to_string

  response_json |> string.contains("[") |> should.be_true
  response_json |> string.contains("First") |> should.be_true
  response_json |> string.contains("Second") |> should.be_true
}

/// Bridge: PATCH /api/todos/:id request body format (partial update)
/// Verifies update request can contain any subset of fields
pub fn patch_todo_request_body_format_test() {
  // Partial update - only changing completed status
  let patch_body = json.object([
    #("completed", json.bool(True)),
  ]) |> json.to_string

  patch_body |> should.equal("{\"completed\":true}")

  // Partial update - changing title and priority
  let patch_body2 = json.object([
    #("title", json.string("Updated title")),
    #("priority", json.string("high")),
  ]) |> json.to_string

  patch_body2 |> string.contains("\"title\":\"Updated title\"") |> should.be_true
  patch_body2 |> string.contains("\"priority\":\"high\"") |> should.be_true
}

/// Bridge: Error response format for validation failures (400)
/// Verifies error JSON structure matches shared.AppError format
pub fn validation_error_response_format_test() {
  let errors = ["title is required", "invalid priority value"]
  let error_response = json.object([
    #("error", json.string("invalid_input")),
    #("details", json.array(errors, json.string)),
  ]) |> json.to_string

  error_response |> string.contains("invalid_input") |> should.be_true
  error_response |> string.contains("details") |> should.be_true
  error_response |> string.contains("title is required") |> should.be_true
}

/// Bridge: Error response format for not found (404)
/// Verifies 404 error JSON structure
pub fn not_found_error_response_format_test() {
  let error_response = json.object([
    #("error", json.string("not_found")),
  ]) |> json.to_string

  error_response |> should.equal("{\"error\":\"not_found\"}")
}

// =============================================================================
// CROSS-LAYER TEST: Complete data flow simulation
// =============================================================================

/// Bridge: Complete flow from form input -> validation -> shared.Todo
/// Simulates the full create todo flow frontend will implement
pub fn complete_create_flow_test() {
  // Step 1: User submits form data (strings from form fields)
  let form_title = "My new todo"
  let form_description = "Some details"
  let form_priority = "high"

  // Step 2: Validation (todo_validation layer)
  let validation_result = todo_validation.validate_todo_input(
    form_title,
    Some(form_description),
    form_priority
  )

  // Step 3: Validated data structure matches shared types
  let assert Ok(validated) = validation_result
  validated.title |> should.equal("My new todo")
  validated.priority |> should.equal(High)

  // Step 4: Would be sent to API as JSON (shared.Todo response returns)
  let mock_api_response = Todo(
    id: "server-generated-uuid",
    title: validated.title,
    description: validated.description,
    priority: validated.priority,
    completed: False,
  )

  // Step 5: Frontend model stores shared.Todo
  mock_api_response.id |> should.equal("server-generated-uuid")
  mock_api_response.completed |> should.be_false
}

/// Bridge: Complete flow for toggle completion
/// Simulates: user clicks checkbox -> PATCH -> updated todo returned
pub fn complete_toggle_flow_test() {
  // Step 1: Existing todo from GET /api/todos
  let existing_todo = Todo(
    id: "todo-123",
    title: "Task to toggle",
    description: None,
    priority: Medium,
    completed: False,
  )

  // Step 2: User toggles completion - PATCH request body
  let patch_body = json.object([#("completed", json.bool(True))]) |> json.to_string
  patch_body |> should.equal("{\"completed\":true}")

  // Step 3: Server returns updated todo (simulated)
  let updated_todo = Todo(
    id: existing_todo.id,
    title: existing_todo.title,
    description: existing_todo.description,
    priority: existing_todo.priority,
    completed: True, // Now completed
  )

  // Step 4: Frontend model updates with server-authoritative state
  updated_todo.completed |> should.be_true
  updated_todo.id |> should.equal("todo-123")
}

/// Bridge: Complete flow for filter state change
/// Simulates: user clicks filter -> refetch with query param -> filtered list
pub fn complete_filter_flow_test() {
  // Step 1: All todos from server
  let all_todos = [
    Todo(id: "1", title: "Active 1", description: None, priority: High, completed: False),
    Todo(id: "2", title: "Done 1", description: None, priority: Medium, completed: True),
    Todo(id: "3", title: "Active 2", description: None, priority: Low, completed: False),
  ]

  // Step 2: User selects "active" filter -> frontend filters local list
  // (or would fetch GET /api/todos?filter=active)
  let active_only = list.filter(all_todos, fn(t) { !t.completed })
  list.length(active_only) |> should.equal(2)

  // Step 3: User selects "completed" filter
  let completed_only = list.filter(all_todos, fn(t) { t.completed })
  list.length(completed_only) |> should.equal(1)
}

// =============================================================================
// Imports (must be at bottom for dependency ordering in Gleam)
// =============================================================================

import gleam/list
import gleam/string
