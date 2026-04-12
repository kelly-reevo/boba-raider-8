import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import shared.{
  High as SharedHigh, InvalidField, Low as SharedLow, Medium as SharedMedium,
  MissingField, new_todo, priority_from_string, todo_to_json,
}
import todo_store.{type TodoStore, TodoData, High, Low, Medium, insert}
import web/server.{type Request, type Response, json_response}

/// Request body for creating a todo
pub type CreateTodoRequest {
  CreateTodoRequest(
    title: String,
    description: Option(String),
    priority: Option(String),
  )
}

/// Error response item
pub type ErrorItem {
  ErrorItem(field: String, message: String)
}

/// Decode CreateTodoRequest from JSON
fn decode_create_request(
  json_str: String,
) -> Result(CreateTodoRequest, List(ErrorItem)) {
  // Define the decoder - decode.optional already returns Option type
  let description_decoder = decode.optional(decode.string)

  let decoder = {
    use title <- decode.field("title", decode.optional(decode.string))
    use description <- decode.field("description", description_decoder)
    use priority <- decode.field("priority", decode.optional(decode.string))

    decode.success(CreateTodoRequest(
      title: option.unwrap(title, ""),
      description: description,
      priority: priority,
    ))
  }

  case json.parse(json_str, decoder) {
    Ok(req) -> {
      // Validate the parsed request
      case validate_request(req) {
        Ok(validated) -> Ok(validated)
        Error(errors) -> Error(errors)
      }
    }
    Error(_) -> {
      // Try to extract what we can and validate
      case extract_title(json_str) {
        None -> Error([ErrorItem(field: "title", message: "Title is required")])
        Some("") -> Error([ErrorItem(field: "title", message: "Title is required")])
        Some(title) -> {
          let desc = extract_description(json_str)
          let priority = extract_priority(json_str)

          let req = CreateTodoRequest(
            title: title,
            description: desc,
            priority: priority,
          )

          case validate_request(req) {
            Ok(validated) -> Ok(validated)
            Error(errors) -> Error(errors)
          }
        }
      }
    }
  }
}

/// Extract title from JSON string
fn extract_title(json: String) -> Option(String) {
  case extract_json_field(json, "title") {
    Some(value) -> Some(value)
    None -> None
  }
}

/// Extract description from JSON string
fn extract_description(json: String) -> Option(String) {
  case extract_json_field(json, "description") {
    Some("null") -> None
    Some(value) -> Some(value)
    None -> None
  }
}

/// Extract priority from JSON string
fn extract_priority(json: String) -> Option(String) {
  case extract_json_field(json, "priority") {
    Some(value) -> Some(value)
    None -> None
  }
}

/// Simple field extraction from JSON
fn extract_json_field(json: String, key: String) -> Option(String) {
  let pattern = "\"" <> key <> "\":"
  case string.split(json, pattern) {
    [_, rest] | [_, rest, ..] -> {
      let trimmed = string.trim_start(rest)
      case trimmed {
        "null" <> _ -> Some("null")
        "true" <> _ -> Some("true")
        "false" <> _ -> Some("false")
        _ -> {
          case string.starts_with(trimmed, "\"") {
            True -> {
              let after_quote = string.drop_start(trimmed, 1)
              case string.split(after_quote, "\"") {
                [value, ..] -> Some(value)
                _ -> None
              }
            }
            False -> {
              // Try to extract unquoted value up to comma or brace
              case string.split(trimmed, ",") {
                [first, ..] -> Some(string.trim_end(first))
                [] -> None
              }
            }
          }
        }
      }
    }
    _ -> None
  }
}

/// Validate the create request
fn validate_request(
  req: CreateTodoRequest,
) -> Result(CreateTodoRequest, List(ErrorItem)) {
  let errors = []

  // Validate title
  let trimmed_title = string.trim(req.title)
  let errors = case trimmed_title {
    "" -> [ErrorItem(field: "title", message: "Title is required"), ..errors]
    _ -> {
      case string.length(trimmed_title) > 200 {
        True -> [
          ErrorItem(field: "title", message: "Title exceeds maximum length of 200 characters"),
          ..errors
        ]
        False -> errors
      }
    }
  }

  // Validate priority if provided
  let errors = case req.priority {
    None -> errors
    Some(p) -> {
      case priority_from_string(p) {
        Ok(_) -> errors
        Error(_) -> [
          ErrorItem(
            field: "priority",
            message: "Priority must be 'low', 'medium', or 'high'",
          ),
          ..errors
        ]
      }
    }
  }

  case errors {
    [] -> Ok(req)
    errs -> Error(list.reverse(errs))
  }
}

/// Convert validation errors to JSON
fn errors_to_json(errors: List(ErrorItem)) -> String {
  let error_objects =
    list.map(errors, fn(e) {
      json.object([
        #("field", json.string(e.field)),
        #("message", json.string(e.message)),
      ])
    })

  json.object([#("errors", json.array(error_objects, fn(x) { x }))])
  |> json.to_string()
}

/// Create a new todo handler
pub fn create(request: Request, store: TodoStore) -> Response {
  // Parse and validate the request body
  case decode_create_request(request.body) {
    Error(errors) -> {
      // Return 422 with field-level errors
      json_response(422, errors_to_json(errors))
    }
    Ok(validated) -> {
      // Create the todo using shared.new_todo
      // Parse priority for shared module (it uses different Priority type)
      let shared_priority = case validated.priority {
        None -> SharedMedium
        Some(p) -> {
          case priority_from_string(p) {
            Ok(sp) -> sp
            Error(_) -> SharedMedium
          }
        }
      }

      case new_todo(
        title: validated.title,
        description: validated.description,
        priority: shared_priority,
      ) {
        Error(validation_errors) -> {
          // Convert shared ValidationError to ErrorItem
          let errors =
            list.map(validation_errors, fn(ve) {
              case ve {
                MissingField(field) ->
                  ErrorItem(field: field, message: field <> " is required")
                InvalidField(field, message) ->
                  ErrorItem(field: field, message: message)
              }
            })
          json_response(422, errors_to_json(errors))
        }
        Ok(new_todo_item) -> {
          // Store via OTP actor - convert priority to store type
          let store_priority = case new_todo_item.priority {
            SharedLow -> Low
            SharedMedium -> Medium
            SharedHigh -> High
          }
          let store_data = TodoData(
            title: new_todo_item.title,
            description: new_todo_item.description,
            priority: store_priority,
            completed: new_todo_item.completed,
            created_at: new_todo_item.created_at,
            updated_at: new_todo_item.updated_at,
          )
          let _ = insert(store, store_data)

          // Return 201 with the created todo
          json_response(201, todo_to_json(new_todo_item))
        }
      }
    }
  }
}

