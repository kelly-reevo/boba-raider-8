/// Global API error handling middleware
/// Catches unhandled exceptions, returns JSON error responses with correct HTTP status codes
/// Ensures all error responses follow consistent {error: string} format

import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/json
import gleam/string
import web/server.{type Request, type Response, json_response}

/// HTTP status codes
const status_bad_request = 400
const status_not_found = 404
const status_unsupported_media_type = 415
const status_internal_server_error = 500

/// Content-Type header name
const header_content_type = "content-type"

/// Error response envelope: {error: string}
fn error_response(status: Int, message: String) -> Response {
  let body = json.object([#("error", json.string(message))])
  |> json.to_string

  json_response(status, body)
}

/// Check if Content-Type is application/json
fn is_json_content_type(headers: Dict(String, String)) -> Bool {
  case dict.get(headers, header_content_type) {
    Ok(value) -> string.contains(string.lowercase(value), "application/json")
    Error(_) -> False
  }
}

/// Check if request method requires JSON body validation
fn requires_json_body(method: String) -> Bool {
  case string.uppercase(method) {
    "POST" -> True
    "PATCH" -> True
    "PUT" -> True
    _ -> False
  }
}

/// Validate that a string is valid JSON by attempting to decode it
fn is_valid_json(body: String) -> Bool {
  // Try to parse as any JSON value
  let decoder = decode.dynamic
  case json.parse(from: body, using: decoder) {
    Ok(_) -> True
    Error(_) -> False
  }
}

/// Check if response follows {error: string} format
fn has_error_string_format(body: String) -> Bool {
  let decoder = {
    use error <- decode.field("error", decode.string)
    decode.success(error)
  }
  case json.parse(from: body, using: decoder) {
    Ok(_) -> True
    Error(_) -> False
  }
}

/// Check if response follows {errors: array} format
fn has_errors_array_format(body: String) -> Bool {
  let error_item_decoder = {
    use field <- decode.field("field", decode.string)
    use message <- decode.field("message", decode.string)
    decode.success(#(field, message))
  }
  let decoder = {
    use errors <- decode.field("errors", decode.list(error_item_decoder))
    decode.success(errors)
  }
  case json.parse(from: body, using: decoder) {
    Ok(_) -> True
    Error(_) -> False
  }
}

/// Wrap a handler with error handling middleware
/// This validates Content-Type and JSON body before passing to handler
pub fn with_error_handling(handler: fn(Request) -> Response) -> fn(Request) -> Response {
  fn(request: Request) {
    // First, validate Content-Type for methods that require JSON body
    case requires_json_body(request.method) {
      True -> {
        case is_json_content_type(request.headers) {
          False -> {
            // Return 415 Unsupported Media Type
            error_response(status_unsupported_media_type, "Unsupported Media Type")
          }
          True -> {
            // Validate JSON body is present and valid
            case string.trim(request.body) {
              "" -> {
                // Empty body is invalid for POST/PATCH with JSON content type
                error_response(status_bad_request, "Invalid JSON in request body")
              }
              body -> {
                case is_valid_json(body) {
                  False -> {
                    // Return 400 Bad Request for malformed JSON
                    error_response(status_bad_request, "Invalid JSON in request body")
                  }
                  True -> {
                    // Body is valid JSON, proceed to handler
                    let response = handler(request)
                    // Ensure error responses follow correct format
                    case response.status >= 400 {
                      True -> ensure_error_format(response)
                      False -> response
                    }
                  }
                }
              }
            }
          }
        }
      }
      False -> {
        // Method doesn't require JSON body validation, proceed directly
        let response = handler(request)
        // Ensure error responses follow correct format
        case response.status >= 400 {
          True -> ensure_error_format(response)
          False -> response
        }
      }
    }
  }
}

/// Ensure error response follows the {error: string} or {errors: []} format
fn ensure_error_format(response: Response) -> Response {
  // Check if response body is already valid JSON error format
  let is_valid_error_format =
    has_error_string_format(response.body) || has_errors_array_format(response.body)

  case is_valid_error_format {
    True -> response
    False -> {
      // Body is not valid JSON error format - replace with standard format
      case response.status {
        404 -> error_response(404, "Not found")
        400 -> error_response(400, "Bad request")
        415 -> error_response(415, "Unsupported Media Type")
        500 -> error_response(500, "Internal server error")
        _ -> error_response(response.status, "Request failed")
      }
    }
  }
}
