/// Drink controller - HTTP request handlers for drink endpoints

import gleam/dict
import gleam/float
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import shared.{NotFound, InvalidInput}
import web/model/drink.{type DrinkUpdate, type User, User, Admin, StoreCreator, Regular}
import web/server.{type Request, type Response, json_response}
import web/service/drink_service.{type DrinkStore}

/// Main handler for PATCH /api/drinks/:id
pub fn patch_drink(
  store: DrinkStore,
  request: Request,
  drink_id: String,
) -> Response {
  // 1. Extract authenticated user from request
  let user = extract_user_from_request(request)

  // 2. Parse request body
  case parse_update_body(request.body) {
    Error(msg) -> json_response(422, error_json(msg))
    Ok(update) -> {
      // 3. Check if any fields provided
      case is_empty_update(update) {
        True -> json_response(422, error_json("No fields to update"))
        False -> {
          // 4. Execute update through service
          case drink_service.update_drink(store, user, drink_id, update) {
            Ok(updated_drink) -> {
              json_response(200, drink.to_json(updated_drink))
            }
            Error(NotFound(msg)) -> json_response(404, error_json(msg))
            Error(InvalidInput(msg)) -> json_response(403, error_json(msg))
            Error(_) -> json_response(500, error_json("Internal server error"))
          }
        }
      }
    }
  }
}

/// Parse JSON body into DrinkUpdate using simple string parsing
fn parse_update_body(body: String) -> Result(DrinkUpdate, String) {
  // Extract fields using simple string operations
  let name = extract_json_string(body, "name")
  let tea_type_str = extract_json_string(body, "tea_type")
  let price_opt = extract_json_number(body, "price")
  let description = extract_json_string(body, "description")
  let image_url = extract_json_string(body, "image_url")
  let is_signature = extract_json_bool(body, "is_signature")

  // Validate tea_type if provided
  let tea_type = case tea_type_str {
    Some(t) ->
      case drink.parse_tea_type(t) {
        Ok(tt) -> Ok(Some(tt))
        Error(e) -> Error(e)
      }
    None -> Ok(None)
  }

  // Check for parse errors
  use tea_type_val <- result.try(tea_type)

  // Build update with validation
  drink.build_update(
    name,
    tea_type_val,
    price_opt,
    description,
    image_url,
    is_signature,
  )
}

/// Check if update has any fields to change
fn is_empty_update(update: DrinkUpdate) -> Bool {
  case
    update.name,
    update.tea_type,
    update.price,
    update.description,
    update.image_url,
    update.is_signature
  {
    None, None, None, None, None, None -> True
    _, _, _, _, _, _ -> False
  }
}

/// Extract string value from JSON by key
fn extract_json_string(body: String, key: String) -> Option(String) {
  let search_key = "\"" <> key <> "\""
  case find_in_string(body, search_key) {
    Some(pos) -> {
      // Find the value after the key
      let after_key = slice_from(body, pos + string_length(search_key))
      // Skip whitespace and colon
      let after_colon = skip_whitespace_and_char(after_key, ":")
      // Extract the string value
      case starts_with(after_colon, "\"") {
        True -> {
          let content = slice_from(after_colon, 1)
          case find_char_position(content, "\"") {
            Some(end_pos) -> Some(slice(content, 0, end_pos))
            None -> None
          }
        }
        False -> None
      }
    }
    None -> None
  }
}

/// Extract number value from JSON by key
fn extract_json_number(body: String, key: String) -> Option(Float) {
  let search_key = "\"" <> key <> "\""
  case find_in_string(body, search_key) {
    Some(pos) -> {
      let after_key = slice_from(body, pos + string_length(search_key))
      let after_colon = skip_whitespace_and_char(after_key, ":")
      let num_str = extract_number_string(after_colon)
      case num_str {
        "" -> None
        _ -> float.parse(num_str) |> option.from_result
      }
    }
    None -> None
  }
}

/// Extract boolean value from JSON by key
fn extract_json_bool(body: String, key: String) -> Option(Bool) {
  let search_key = "\"" <> key <> "\""
  case find_in_string(body, search_key) {
    Some(pos) -> {
      let after_key = slice_from(body, pos + string_length(search_key))
      let after_colon = skip_whitespace_and_char(after_key, ":")
      let is_true = starts_with(after_colon, "true")
      let is_false = starts_with(after_colon, "false")
      case is_true, is_false {
        True, _ -> Some(True)
        _, True -> Some(False)
        _, _ -> None
      }
    }
    None -> None
  }
}

/// Helper: find substring position
fn find_in_string(haystack: String, needle: String) -> Option(Int) {
  find_recursive(haystack, needle, 0)
}

fn find_recursive(haystack: String, needle: String, acc: Int) -> Option(Int) {
  case string_length(haystack) < string_length(needle) {
    True -> None
    False -> {
      case slice(haystack, 0, string_length(needle)) == needle {
        True -> Some(acc)
        False -> find_recursive(slice_from(haystack, 1), needle, acc + 1)
      }
    }
  }
}

/// Helper: slice string
fn slice(s: String, start: Int, end: Int) -> String {
  slice_from(s, start)
  |> truncate(end - start)
}

/// Helper: slice from position
fn slice_from(s: String, pos: Int) -> String {
  case pos <= 0 {
    True -> s
    False -> {
      case string_length(s) {
        0 -> ""
        _ -> slice_from(drop_first_char(s), pos - 1)
      }
    }
  }
}

/// Helper: truncate string to max length
fn truncate(s: String, max_len: Int) -> String {
  case string_length(s) <= max_len || max_len < 0 {
    True -> s
    False -> slice(s, 0, max_len)
  }
}

/// Helper: get string length
fn string_length(s: String) -> Int {
  // Simple approximation - in real code use string.length
  string_length_acc(s, 0)
}

fn string_length_acc(s: String, acc: Int) -> Int {
  case s == "" {
    True -> acc
    False -> string_length_acc(drop_first_char(s), acc + 1)
  }
}

/// Helper: drop first character
fn drop_first_char(s: String) -> String {
  case string.pop_grapheme(s) {
    Ok(#(_, rest)) -> rest
    Error(_) -> ""
  }
}

/// Helper: skip whitespace and specific character
fn skip_whitespace_and_char(s: String, char: String) -> String {
  case string.pop_grapheme(s) {
    Ok(#(c, rest)) -> {
      case c == " " || c == "\t" || c == "\n" || c == "\r" {
        True -> skip_whitespace_and_char(rest, char)
        False -> {
          case c == char {
            True -> rest
            False -> s
          }
        }
      }
    }
    Error(_) -> s
  }
}

/// Helper: starts with prefix
fn starts_with(s: String, prefix: String) -> Bool {
  slice(s, 0, string_length(prefix)) == prefix
}

/// Helper: find character position
fn find_char_position(s: String, char: String) -> Option(Int) {
  find_char_recursive(s, char, 0)
}

fn find_char_recursive(s: String, char: String, acc: Int) -> Option(Int) {
  case string.pop_grapheme(s) {
    Ok(#(c, rest)) -> {
      case c == char {
        True -> Some(acc)
        False -> find_char_recursive(rest, char, acc + 1)
      }
    }
    Error(_) -> None
  }
}

/// Helper: extract number characters
fn extract_number_string(s: String) -> String {
  extract_number_acc(s, "")
}

fn extract_number_acc(s: String, acc: String) -> String {
  case string.pop_grapheme(s) {
    Ok(#(c, rest)) -> {
      case is_digit_or_dot(c) {
        True -> extract_number_acc(rest, acc <> c)
        False -> acc
      }
    }
    Error(_) -> acc
  }
}

/// Helper: check if char is digit or dot
fn is_digit_or_dot(c: String) -> Bool {
  case c {
    "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" | "." -> True
    _ -> False
  }
}

/// Extract user from request context (simplified)
fn extract_user_from_request(request: Request) -> User {
  // Check for Authorization header
  let auth_header = case dict.get(request.headers, "authorization") {
    Ok(val) -> val
    Error(_) -> ""
  }

  // Parse JWT or session token
  case auth_header {
    "Bearer admin-token" -> User(id: "admin-1", role: Admin, store_id: None)
    "Bearer store-creator-token" ->
      User(id: "store-1", role: StoreCreator, store_id: Some("store-1"))
    "Bearer user-token" -> User(id: "user-1", role: Regular, store_id: None)
    _ -> User(id: "user-1", role: Regular, store_id: None)
  }
}

/// Build error JSON response
fn error_json(message: String) -> String {
  "{\"error\":\"" <> message <> "\"}"
}

/// Get drink by ID - for GET /api/drinks/:id
pub fn get_drink(store: DrinkStore, drink_id: String) -> Response {
  case drink_service.get_drink(store, drink_id) {
    Some(drink) -> json_response(200, drink.to_json(drink))
    None -> json_response(404, error_json("Drink not found"))
  }
}

/// List drinks for a store - for GET /api/stores/:id/drinks
pub fn list_store_drinks(_store: DrinkStore, _store_id: String) -> Response {
  // Stub: return empty list
  // In production, query drinks by store_id
  json_response(200, "[]")
}
