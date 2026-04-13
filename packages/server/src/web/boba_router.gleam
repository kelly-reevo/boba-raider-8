/// Boba Router - HTTP request routing for boba-raider-8 API
/// Handles GET /api/stores/:id and other store-related endpoints

import gleam/json
import gleam/option.{type Option, Some, None}
import gleam/string
import boba_store.{type Store}
import store/store_service as service
import web/server.{type Request, type Response}

// ============================================================================
// Router Factory
// ============================================================================

/// Create an HTTP handler that uses the given store
pub fn make_handler(store: Store) -> fn(Request) -> Response {
  fn(request: Request) { route(store, request) }
}

// ============================================================================
// Routing Logic
// ============================================================================

fn route(store: Store, request: Request) -> Response {
  case request.method, request.path {
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "GET", path -> route_get(store, path)
    _, _ -> not_found()
  }
}

fn route_get(store: Store, path: String) -> Response {
  // Check for /api/stores/:id pattern
  case string.starts_with(path, "/api/stores/") {
    True -> {
      let id_part = string.drop_start(path, 12) // Remove "/api/stores/"
      case string.is_empty(id_part) {
        True -> not_found()
        False -> get_store_handler(store, id_part)
      }
    }
    False -> not_found()
  }
}

// ============================================================================
// Handlers
// ============================================================================

fn health_handler() -> Response {
  server.json_response(
    200,
    json.object([#("status", json.string("ok"))])
    |> json.to_string,
  )
}

fn not_found() -> Response {
  server.json_response(
    404,
    json.object([#("error", json.string("store not found"))])
    |> json.to_string,
  )
}

fn get_store_handler(store: Store, store_id_str: String) -> Response {
  // Parse the store ID as an integer
  case parse_int(store_id_str) {
    Error(_) -> {
      // Invalid ID format (not a number)
      server.json_response(
        400,
        json.object([#("error", json.string("Invalid store ID format"))])
        |> json.to_string,
      )
    }
    Ok(store_id) -> {
      // Look up the store by numeric ID
      case boba_store.get_store_by_id(store, store_id) {
        Ok(store_data) -> {
          // Get actual drink count from drink store
          let drink_count = boba_store.count_drinks_by_store(store, store_id)

          // Return store with actual drink count
          let json_body = store_record_to_json(store_data, drink_count)
          server.json_response(200, json.to_string(json_body))
        }
        Error(msg) -> {
          // Store not found or other error
          case string.contains(msg, "not found") || string.contains(msg, "Not found") {
            True -> server.json_response(
              404,
              json.object([#("error", json.string("store not found"))])
              |> json.to_string,
            )
            False -> server.json_response(
              400,
              json.object([#("error", json.string(msg))])
              |> json.to_string,
            )
          }
        }
      }
    }
  }
}

/// Parse a string to an integer
fn parse_int(s: String) -> Result(Int, String) {
  parse_int_recursive(string.trim(s), 0)
}

fn parse_int_recursive(s: String, acc: Int) -> Result(Int, String) {
  case string.pop_grapheme(s) {
    Ok(#(c, rest)) -> {
      case c {
        "0" -> parse_int_recursive(rest, acc * 10 + 0)
        "1" -> parse_int_recursive(rest, acc * 10 + 1)
        "2" -> parse_int_recursive(rest, acc * 10 + 2)
        "3" -> parse_int_recursive(rest, acc * 10 + 3)
        "4" -> parse_int_recursive(rest, acc * 10 + 4)
        "5" -> parse_int_recursive(rest, acc * 10 + 5)
        "6" -> parse_int_recursive(rest, acc * 10 + 6)
        "7" -> parse_int_recursive(rest, acc * 10 + 7)
        "8" -> parse_int_recursive(rest, acc * 10 + 8)
        "9" -> parse_int_recursive(rest, acc * 10 + 9)
        _ -> Error("Invalid digit")
      }
    }
    Error(_) -> Ok(acc)
  }
}

// ============================================================================
// JSON Encoding
// ============================================================================

fn store_record_to_json(store: service.StoreWithDrinkCount, drink_count: Int) -> json.Json {
  json.object([
    #("id", json.string(store.id)),
    #("name", json.string(store.name)),
    #("address", encode_optional_string(store.address)),
    #("city", encode_optional_string(store.city)),
    #("phone", encode_optional_string(store.phone)),
    #("drink_count", json.int(drink_count)),
    #("created_at", json.string(store.created_at)),
  ])
}

fn encode_optional_string(opt: Option(String)) -> json.Json {
  case opt {
    Some(s) -> json.string(s)
    None -> json.null()
  }
}
