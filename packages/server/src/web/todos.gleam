import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some, flatten as option_flatten}
import gleam/string
import shared.{type Priority, type Todo, Low, Medium, High}
import todo_store.{type TodoStore}
import web/server.{type Request, type Response, json_response}

// ============================================================================
// Types
// ============================================================================

/// Partial update request body - all fields optional
/// Uses Dict to check which fields were actually provided vs omitted
pub type PatchTodoRequest {
  PatchTodoRequest(
    title: Option(String),
    description: Option(Option(String)),
    priority: Option(Priority),
    completed: Option(Bool),
  )
}

/// Validation error for a specific field
pub type FieldError {
  FieldError(field: String, message: String)
}

// ============================================================================
// JSON Decoding
// ============================================================================

/// Decode priority from string, returning Error for invalid values
fn decode_priority(str: String) -> Result(Priority, String) {
  case shared.priority_from_string(str) {
    Ok(p) -> Ok(p)
    Error(_) -> Error("Priority must be 'low', 'medium', or 'high'")
  }
}

/// Decoder for priority that validates the string value
fn priority_decoder() -> decode.Decoder(Priority) {
  decode.string
  |> decode.then(fn(str) {
    case decode_priority(str) {
      Ok(p) -> decode.success(p)
      Error(msg) -> decode.failure(Low, msg)
    }
  })
}

/// Decoder for optional priority that validates if present
fn optional_priority_decoder() -> decode.Decoder(Option(Priority)) {
  decode.optional(priority_decoder())
}

/// Decoder for PatchTodoRequest - all fields optional
fn patch_request_decoder() -> decode.Decoder(PatchTodoRequest) {
  use title <- decode.field("title", decode.optional(decode.string))
  use description <- decode.field(
    "description",
    decode.optional(decode.optional(decode.string)),
  )
  use priority <- decode.field("priority", optional_priority_decoder())
  use completed <- decode.field("completed", decode.optional(decode.bool))

  decode.success(PatchTodoRequest(
    title: title,
    description: description,
    priority: priority,
    completed: completed,
  ))
}

// ============================================================================
// Validation
// ============================================================================

/// Check if a key exists in the JSON body by simple string search
fn has_field(json_str: String, field: String) -> Bool {
  // Simple check: look for "field": in the JSON
  let pattern = "\"" <> field <> "\":"
  string.contains(json_str, pattern)
}

/// Validate a partial update request
fn validate_patch_request(
  request: PatchTodoRequest,
  json_str: String,
) -> Result(PatchTodoRequest, List(FieldError)) {
  let errors = []

  // Validate title if provided
  let errors = case has_field(json_str, "title") {
    True ->
      case request.title {
        None -> [FieldError("title", "Title must be a string"), ..errors]
        Some(title) -> {
          let trimmed = string.trim(title)
          let len = string.length(trimmed)
          case trimmed {
            "" -> [FieldError("title", "Title cannot be empty"), ..errors]
            _ if len > 200 -> [
              FieldError(
                "title",
                "Title exceeds maximum length of 200 characters",
              ),
              ..errors
            ]
            _ -> errors
          }
        }
      }
    False -> errors
  }

  // Validate description if provided (can be null or string)
  let errors = case has_field(json_str, "description") {
    True ->
      case request.description {
        None -> [
          FieldError("description", "Description must be a string or null"),
          ..errors
        ]
        Some(Some(desc)) -> {
          let len = string.length(desc)
          case len > 2000 {
            True -> [
              FieldError(
                "description",
                "Description exceeds maximum length of 2000 characters",
              ),
              ..errors
            ]
            False -> errors
          }
        }
        Some(None) -> errors // null is valid
      }
    False -> errors
  }

  // Validate priority if provided - already validated by decoder
  // but we need to catch parse failures
  let errors = case has_field(json_str, "priority") {
    True ->
      case request.priority {
        None -> [
          FieldError("priority", "Priority must be 'low', 'medium', or 'high'"),
          ..errors
        ]
        Some(_) -> errors
      }
    False -> errors
  }

  // Validate completed if provided
  let errors = case has_field(json_str, "completed") {
    True ->
      case request.completed {
        None -> [
          FieldError("completed", "Completed must be a boolean"),
          ..errors
        ]
        Some(_) -> errors
      }
    False -> errors
  }

  case errors {
    [] -> Ok(request)
    _ -> Error(list.reverse(errors))
  }
}

// ============================================================================
// Helpers
// ============================================================================

/// Extract ID from path like /api/todos/:id
fn extract_todo_id(path: String) -> Option(String) {
  let parts = string.split(path, "/")
  case parts {
    [_, "api", "todos", id] -> Some(id)
    ["api", "todos", id] -> Some(id)
    _ -> None
  }
}

/// Convert TodoStore TodoItem to shared Todo type
fn store_item_to_shared_todo(item: todo_store.TodoItem) -> Todo {
  let priority = case item.priority {
    todo_store.Low -> Low
    todo_store.Medium -> Medium
    todo_store.High -> High
  }

  // Generate timestamps for store items (they don't have timestamps)
  let timestamp = shared.generate_timestamp()

  shared.Todo(
    id: item.id,
    title: item.title,
    description: item.description,
    priority: priority,
    completed: item.completed,
    created_at: timestamp,
    updated_at: timestamp,
  )
}

/// Convert shared Todo to todo_store TodoData
fn shared_todo_to_store_data(item: shared.Todo) -> todo_store.TodoData {
  let priority = case item.priority {
    Low -> todo_store.Low
    Medium -> todo_store.Medium
    High -> todo_store.High
  }

  todo_store.TodoData(
    title: item.title,
    description: item.description,
    priority: priority,
    completed: item.completed,
    created_at: item.created_at,
    updated_at: item.updated_at,
  )
}

/// Serialize Todo to JSON response
fn todo_to_json_response(item: shared.Todo) -> String {
  let description_value = case item.description {
    Some(desc) -> json.string(desc)
    None -> json.null()
  }

  json.object([
    #("id", json.string(item.id)),
    #("title", json.string(item.title)),
    #("description", description_value),
    #("priority", json.string(shared.priority_to_string(item.priority))),
    #("completed", json.bool(item.completed)),
    #("created_at", json.string(item.created_at)),
    #("updated_at", json.string(item.updated_at)),
  ])
  |> json.to_string()
}

/// Serialize validation errors to JSON
fn errors_to_json(errors: List(FieldError)) -> String {
  let error_objects = list.map(errors, fn(e) {
    json.object([
      #("field", json.string(e.field)),
      #("message", json.string(e.message)),
    ])
  })

  json.object([#("errors", json.array(error_objects, of: fn(x) { x }))])
  |> json.to_string()
}

// ============================================================================
// Handlers
// ============================================================================

/// Handle POST /api/todos - create a new todo
pub fn create_todo(
  store: TodoStore,
  request: Request,
) -> Response {
  // Parse the request body as JSON
  case json.parse(request.body, create_request_decoder()) {
    Ok(create_req) -> {
      case validate_create_request(create_req) {
        Ok(validated) -> {
          // Convert priority
          let store_priority = case validated.priority {
            Low -> todo_store.Low
            Medium -> todo_store.Medium
            High -> todo_store.High
          }

          // Create TodoData for store with timestamps
          let timestamp = shared.generate_timestamp()
          let data = todo_store.TodoData(
            title: validated.title,
            description: validated.description,
            priority: store_priority,
            completed: False,
            created_at: timestamp,
            updated_at: timestamp,
          )

          // Insert into store
          let id = todo_store.insert(store, data)

          // Get the inserted todo to return
          case todo_store.get(store, id) {
            Some(item) -> {
              let created_item = store_item_to_shared_todo(item)
              json_response(201, todo_to_json_response(created_item))
            }
            None ->
              json_response(
                500,
                json.object([#("error", json.string("Failed to create todo"))])
                |> json.to_string(),
              )
          }
        }
        Error(errors) -> json_response(422, errors_to_json(errors))
      }
    }
    Error(_) -> {
      // Invalid JSON structure
      json_response(
        422,
        json.object([#("errors", json.array([], of: fn(x) { x }))])
        |> json.to_string(),
      )
    }
  }
}

/// Create request type - after validation all fields are guaranteed to be present
pub type ValidatedCreateRequest {
  ValidatedCreateRequest(
    title: String,
    description: Option(String),
    priority: Priority,
  )
}

/// Create request type for initial parsing
pub type CreateTodoRequest {
  CreateTodoRequest(
    title: Option(String),
    description: Option(String),
    priority: Option(Priority),
  )
}

/// Decoder for CreateTodoRequest
fn create_request_decoder() -> decode.Decoder(CreateTodoRequest) {
  use title <- decode.field("title", decode.optional(decode.string))
  use description <- decode.field(
    "description",
    decode.optional(decode.optional(decode.string)),
  )
  use priority <- decode.field(
    "priority",
    decode.optional(priority_decoder()),
  )

  decode.success(CreateTodoRequest(
    title: title,
    description: option_flatten(description),
    priority: priority,
  ))
}

/// Validate create request
fn validate_create_request(
  request: CreateTodoRequest,
) -> Result(ValidatedCreateRequest, List(FieldError)) {
  // Validate title
  let #(maybe_title, errors) = case request.title {
    None -> #(None, [FieldError("title", "Title is required")])
    Some(title) -> {
      let trimmed = string.trim(title)
      let len = string.length(trimmed)
      case trimmed {
        "" -> #(None, [FieldError("title", "Title cannot be empty")])
        _ if len > 200 -> #(None, [
          FieldError(
            "title",
            "Title exceeds maximum length of 200 characters",
          ),
        ])
        _ -> #(Some(trimmed), [])
      }
    }
  }

  // Validate description if provided
  let errors = case request.description {
    Some(desc) -> {
      let len = string.length(desc)
      case len > 2000 {
        True -> [
          FieldError(
            "description",
            "Description exceeds maximum length of 2000 characters",
          ),
          ..errors
        ]
        False -> errors
      }
    }
    None -> errors
  }

  // Set priority with default
  let priority = case request.priority {
    Some(p) -> p
    None -> Medium
  }

  case errors {
    [] -> {
      // At this point, maybe_title is guaranteed to be Some (validated above)
      let title = case maybe_title {
        Some(t) -> t
        None -> ""
      }
      Ok(ValidatedCreateRequest(
        title: title,
        description: request.description,
        priority: priority,
      ))
    }
    _ -> Error(errors)
  }
}

/// Strip query string from path
fn strip_query_string(path: String) -> String {
  case string.split(path, "?") {
    [path_only, _] -> path_only
    _ -> path
  }
}

/// Handle PATCH /api/todos/:id
pub fn patch_todo(
  store: TodoStore,
  request: Request,
) -> Response {
  // Extract todo ID from path (strip query string first)
  let path_only = strip_query_string(request.path)
  let maybe_id = extract_todo_id(path_only)
  case maybe_id {
    None ->
      json_response(
        404,
        json.object([#("error", json.string("Todo not found"))])
        |> json.to_string(),
      )
    Some(id) -> {
      // Check if todo exists
      case todo_store.get(store, id) {
        None ->
          json_response(
            404,
            json.object([#("error", json.string("Todo not found"))])
            |> json.to_string(),
          )
        Some(existing) -> {
          // Parse and validate the request body
          case json.parse(request.body, patch_request_decoder()) {
            Ok(patch_request) -> {
              case validate_patch_request(patch_request, request.body) {
                Ok(validated) -> {
                  // Apply partial updates to existing todo
                  let updated_todo = apply_updates(existing, validated)

                  // Convert to store format and save
                  let store_data = shared_todo_to_store_data(updated_todo)
                  case todo_store.update(store, id, store_data) {
                    todo_store.UpdateOk -> {
                      json_response(200, todo_to_json_response(updated_todo))
                    }
                    todo_store.NotFound ->
                      json_response(
                        404,
                        json.object([#("error", json.string("Todo not found"))])
                        |> json.to_string(),
                      )
                  }
                }
                Error(errors) -> {
                  json_response(422, errors_to_json(errors))
                }
              }
            }
            Error(_) -> {
              // Invalid JSON structure
              json_response(
                422,
                json.object([#("errors", json.array([], of: fn(x) { x }))])
                |> json.to_string(),
              )
            }
          }
        }
      }
    }
  }
}

/// Apply partial updates to an existing todo
fn apply_updates(
  existing: todo_store.TodoItem,
  patch: PatchTodoRequest,
) -> Todo {
  // Convert existing item to shared Todo format first
  let base = store_item_to_shared_todo(existing)

  // Get current timestamp for update
  let new_timestamp = shared.generate_timestamp()

  // Apply updates - use existing values if field not provided in patch
  let new_title = case patch.title {
    Some(title) -> title
    None -> base.title
  }

  let new_description = case patch.description {
    Some(desc) -> desc
    None -> base.description
  }

  let new_priority = case patch.priority {
    Some(p) -> p
    None -> base.priority
  }

  let new_completed = case patch.completed {
    Some(c) -> c
    None -> base.completed
  }

  // Return updated todo with new timestamp
  shared.Todo(
    id: base.id,
    title: new_title,
    description: new_description,
    priority: new_priority,
    completed: new_completed,
    created_at: base.created_at,
    updated_at: new_timestamp,
  )
}
