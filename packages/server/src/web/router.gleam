import actors/todo_actor.{type TodoActor, Updated, NotFound}
import gleam/dict.{type Dict}
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import models/todo_item.{type Todo}
import web/server.{type Request, type Response, json_response}

/// Creates a handler function that routes requests using the provided actor
pub fn make_handler(store: TodoActor) -> fn(Request) -> Response {
  fn(request: Request) { route(request, store) }
}

/// Route incoming requests to appropriate handlers
fn route(request: Request, store: TodoActor) -> Response {
  case request.method, request.path {
    "GET", "/" -> static_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "PATCH", path -> handle_patch(path, request, store)
    _, _ -> not_found()
  }
}

/// Handle PATCH requests for /api/todos/:id
fn handle_patch(path: String, request: Request, store: TodoActor) -> Response {
  case extract_api_todo_id(path) {
    Some(id) -> patch_todo_handler(id, request, store)
    None -> not_found()
  }
}

/// Extract todo ID from /api/todos/:id path pattern
fn extract_api_todo_id(path: String) -> Option(String) {
  let prefix = "/api/todos/"
  case string.starts_with(path, prefix) {
    True -> {
      let id = string.slice(path, string.length(prefix), string.length(path))
      // Ensure there's an ID and no extra path segments
      case string.is_empty(id), string.contains(id, "/") {
        False, False -> Some(id)
        _, _ -> None
      }
    }
    False -> None
  }
}

/// PATCH /api/todos/:id handler - partial update with validation
fn patch_todo_handler(id: String, request: Request, store: TodoActor) -> Response {
  // Parse the request body
  let updates_result = parse_patch_body(request.body)

  case updates_result {
    Ok(updates) -> {
      // Validate provided fields
      let errors = validate_patch_updates(updates)

      case list.is_empty(errors) {
        True -> {
          // All valid, call actor to update
          // Convert description: Option(Option(String)) -> Option(String)
          // None = not provided (don't update), Some(None) = set to null, Some(Some(s)) = set to string
          let description_for_actor = case updates.description {
            None -> None  // Not provided, don't update
            Some(None) -> Some("")  // Set to null (using empty string as sentinel)
            Some(Some(s)) -> Some(s)  // Set to string
          }

          let result = todo_actor.update(
            store,
            id,
            todo_actor.UpdateRequest(
              title: updates.title,
              description: description_for_actor,
              priority: updates.priority,
              completed: updates.completed,
            ),
          )

          case result {
            Updated(item) -> {
              json_response(200, todo_to_json_string(item))
            }
            NotFound -> {
              json_response(
                404,
                json.object([#("error", json.string("Todo not found"))])
                  |> json.to_string(),
              )
            }
          }
        }
        False -> {
          // Validation errors - return 422
          let errors_json =
            list.map(errors, fn(e) {
              json.object([
                #("field", json.string(e.field)),
                #("message", json.string(e.message)),
              ])
            })

          json_response(
            422,
            json.object([#("errors", json.array(errors_json, of: fn(x) { x }))])
              |> json.to_string(),
          )
        }
      }
    }
    Error(_) -> {
      // Invalid JSON
      json_response(
        422,
        json.object([
          #(
            "errors",
            json.array(
              [json.object([
                #("field", json.string("body")),
                #("message", json.string("Invalid JSON")),
              ])],
              of: fn(x) { x },
            ),
          ),
        ])
          |> json.to_string(),
      )
    }
  }
}

/// Structure for parsed PATCH body fields
/// For description: None = not provided, Some(None) = provided as null, Some(Some(str)) = provided as string
type PatchUpdates {
  PatchUpdates(
    title: Option(String),
    description: Option(Option(String)),
    priority: Option(String),
    completed: Option(Bool),
  )
}

/// Validation error record
type ValidationError {
  ValidationError(field: String, message: String)
}

/// Parse JSON body into PatchUpdates structure
/// Uses a simple string-based parser for the PATCH body
fn parse_patch_body(body: String) -> Result(PatchUpdates, String) {
  // Simple JSON object parsing for our specific use case
  let cleaned = string.trim(body)

  // Check if it's a valid JSON object
  case string.starts_with(cleaned, "{") && string.ends_with(cleaned, "}") {
    True -> {
      // Remove braces and extract content
      let content = string.slice(cleaned, 1, string.length(cleaned) - 2)

      // Parse key-value pairs
      let fields = parse_json_object(content)

      let title = dict.get(fields, "title") |> option.from_result
      let priority = dict.get(fields, "priority") |> option.from_result

      // Handle description: can be string, null, or missing
      let description = case dict.has_key(fields, "description") {
        True -> {
          case dict.get(fields, "description") {
            Ok("__null__") -> Some(None)
            Ok(s) -> Some(Some(s))
            Error(_) -> None
          }
        }
        False -> None
      }

      // Handle completed: can be true, false, or missing
      let completed = case dict.get(fields, "completed") {
        Ok("true") -> Some(True)
        Ok("false") -> Some(False)
        _ -> None
      }

      Ok(PatchUpdates(title, description, priority, completed))
    }
    False -> Error("Invalid JSON: not an object")
  }
}

/// Parse a JSON object content string into a Dict of field names to values
/// Handles string values, null, and boolean values
fn parse_json_object(content: String) -> Dict(String, String) {
  let pairs = split_json_pairs(content)

  list.fold(pairs, dict.new(), fn(acc, pair) {
    case parse_json_pair(pair) {
      Ok(#(key, value)) -> dict.insert(acc, key, value)
      Error(_) -> acc
    }
  })
}

/// Split JSON object content into individual key:value pairs
/// Handles nested braces by tracking depth
fn split_json_pairs(content: String) -> List(String) {
  split_at_top_level(content, 0, [], "")
}

/// Recursively split string at top-level commas
fn split_at_top_level(
  remaining: String,
  depth: Int,
  acc: List(String),
  current: String,
) -> List(String) {
  case string.pop_grapheme(remaining) {
    // End of string
    Error(_) -> {
      let trimmed = string.trim(current)
      case string.is_empty(trimmed) {
        True -> list.reverse(acc)
        False -> list.reverse([trimmed, ..acc])
      }
    }
    // Opening brace increases depth
    Ok(#("{", rest)) -> {
      split_at_top_level(rest, depth + 1, acc, current <> "{")
    }
    // Closing brace decreases depth
    Ok(#("}", rest)) -> {
      split_at_top_level(rest, depth - 1, acc, current <> "}")
    }
    // Comma at top level splits
    Ok(#(",", rest)) if depth == 0 -> {
      let trimmed = string.trim(current)
      split_at_top_level(rest, depth, [trimmed, ..acc], "")
    }
    // Any other character
    Ok(#(char, rest)) -> {
      split_at_top_level(rest, depth, acc, current <> char)
    }
  }
}

/// Parse a single key:value pair
fn parse_json_pair(pair: String) -> Result(#(String, String), String) {
  let trimmed = string.trim(pair)

  // Find the colon separator
  case find_colon_index(trimmed, 0, 0) {
    Ok(colon_idx) -> {
      let key_part = string.slice(trimmed, 0, colon_idx) |> string.trim
      let value_part = string.slice(trimmed, colon_idx + 1, string.length(trimmed)) |> string.trim

      // Extract key (remove quotes)
      let key = extract_json_string(key_part)

      // Parse value
      let value = parse_json_value(value_part)

      Ok(#(key, value))
    }
    Error(_) -> Error("No colon found in pair")
  }
}

/// Find index of top-level colon (not inside quotes)
fn find_colon_index(s: String, idx: Int, quote_depth: Int) -> Result(Int, String) {
  case string.pop_grapheme(s) {
    Error(_) -> Error("No colon found")
    Ok(#("\"", rest)) -> find_colon_index(rest, idx + 1, quote_depth + 1)
    Ok(#(":", _)) if quote_depth % 2 == 0 -> Ok(idx)
    Ok(#(_, rest)) -> find_colon_index(rest, idx + 1, quote_depth)
  }
}

/// Extract a JSON string (remove surrounding quotes)
fn extract_json_string(s: String) -> String {
  let trimmed = string.trim(s)
  case string.starts_with(trimmed, "\"") && string.ends_with(trimmed, "\"") {
    True -> string.slice(trimmed, 1, string.length(trimmed) - 2)
    False -> trimmed
  }
}

/// Parse a JSON value into a string representation
fn parse_json_value(s: String) -> String {
  let trimmed = string.trim(s)

  // Check if it's a string (starts and ends with quotes)
  let is_string = string.starts_with(trimmed, "\"") && string.ends_with(trimmed, "\"")

  case trimmed {
    // null value
    "null" -> "__null__"
    // String value (remove quotes) - check with guard outside case
    _ if is_string -> string.slice(trimmed, 1, string.length(trimmed) - 2)
    // Boolean or number - return as-is
    _ -> trimmed
  }
}

/// Validate patch updates and return list of errors
fn validate_patch_updates(updates: PatchUpdates) -> List(ValidationError) {
  let errors = []

  // Validate title if provided
  let errors = case updates.title {
    Some("") -> [ValidationError("title", "Title cannot be empty"), ..errors]
    _ -> errors
  }

  // Validate priority if provided
  let errors = case updates.priority {
    Some(p) ->
      case p {
        "low" | "medium" | "high" -> errors
        _ -> [ValidationError("priority", "Priority must be low, medium, or high"), ..errors]
      }
    None -> errors
  }

  list.reverse(errors)
}

/// Convert a Todo to JSON string
fn todo_to_json_string(item: Todo) -> String {
  let description_json = case item.description {
    Some(d) -> json.string(d)
    None -> json.null()
  }

  json.object([
    #("id", json.string(item.id)),
    #("title", json.string(item.title)),
    #("description", description_json),
    #("priority", json.string(todo_item.priority_to_string(item.priority))),
    #("completed", json.bool(item.completed)),
    #("created_at", json.int(item.created_at)),
    #("updated_at", json.int(item.updated_at)),
  ])
  |> json.to_string()
}

/// Static index response
fn static_index() -> Response {
  json_response(
    200,
    json.object([#("status", json.string("ok"))])
      |> json.to_string(),
  )
}

/// Health check handler
fn health_handler() -> Response {
  json_response(
    200,
    json.object([#("status", json.string("ok"))])
      |> json.to_string(),
  )
}

/// Not found response
fn not_found() -> Response {
  json_response(
    404,
    json.object([#("error", json.string("Not found"))])
      |> json.to_string(),
  )
}
