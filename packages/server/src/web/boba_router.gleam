/// HTTP Router for boba-raider-8 API
/// Handles GET /api/drinks/:id and other endpoints

import gleam/int
import gleam/json
import gleam/option.{None, Some}
import gleam/string

import boba_store.{type BobaStore, type DrinkRecord, type RatingAggregates}
import boba_types.{type Store}
import web/server.{type Request, type Response, json_response}

/// Creates a handler function that routes requests
pub fn make_handler(store: BobaStore) -> fn(Request) -> Response {
  fn(request: Request) { route(store, request) }
}

/// Main routing logic
fn route(store: BobaStore, request: Request) -> Response {
  case request.method, request.path {
    "GET", path -> route_get(store, path)
    _, _ -> not_found()
  }
}

/// Handle GET requests
fn route_get(store: BobaStore, path: String) -> Response {
  // Check for /api/drinks/:id pattern
  case string.starts_with(path, "/api/drinks/") {
    True -> {
      let prefix_length = string.length("/api/drinks/")
      let id_part = string.slice(from: path, at_index: prefix_length, length: string.length(path) - prefix_length)
      handle_get_drink(store, id_part)
    }
    False -> not_found()
  }
}

/// Handle GET /api/drinks/:id
fn handle_get_drink(store: BobaStore, id_str: String) -> Response {
  // Parse the ID
  case int.parse(id_str) {
    Ok(id) -> {
      // Validate ID is positive
      case id > 0 {
        True -> fetch_and_respond_drink(store, id)
        False -> not_found()
      }
    }
    Error(_) -> {
      // Invalid ID format
      bad_request("Invalid drink ID format")
    }
  }
}

/// Fetch drink data and build response
fn fetch_and_respond_drink(store: BobaStore, drink_id: Int) -> Response {
  // Get the drink record
  case boba_store.get_drink_by_id(store, drink_id) {
    Ok(drink_record) -> {
      // Get the associated store
      case boba_store.get_store_by_id(store, drink_record.store_id) {
        Ok(store_record) -> {
          // Get rating aggregates
          let aggregates = boba_store.get_rating_aggregates(store, drink_id)

          // Build and return response
          json_response(200, build_drink_json(drink_record, store_record, aggregates))
        }
        Error(_) -> {
          // Store not found but drink exists - internal error
          internal_error("Associated store not found")
        }
      }
    }
    Error(_) -> {
      // Drink not found
      not_found()
    }
  }
}

/// Build JSON response for drink with store and aggregates
fn build_drink_json(
  drink: DrinkRecord,
  store: Store,
  aggregates: RatingAggregates,
) -> String {
  json.object([
    #("id", json.int(drink.id)),
    #("store", json.object([
      #("id", json.int(store.id)),
      #("name", json.string(store.name)),
    ])),
    #("name", json.string(drink.name)),
    #("description", case drink.description {
      Some(d) -> json.string(d)
      None -> json.null()
    }),
    #("base_tea_type", case drink.base_tea_type {
      Some(t) -> json.string(t)
      None -> json.null()
    }),
    #("price", case drink.price {
      Some(p) -> json.float(p)
      None -> json.null()
    }),
    #("aggregates", json.object([
      #("overall_rating", json.float(aggregates.overall_rating)),
      #("sweetness", json.float(aggregates.sweetness)),
      #("boba_texture", json.float(aggregates.boba_texture)),
      #("tea_strength", json.float(aggregates.tea_strength)),
      #("count", json.int(aggregates.count)),
    ])),
    #("created_at", json.string(drink.created_at)),
  ])
  |> json.to_string
}

/// 404 Not Found response
fn not_found() -> Response {
  json_response(
    404,
    json.object([#("error", json.string("Drink not found"))])
    |> json.to_string,
  )
}

/// 400 Bad Request response
fn bad_request(message: String) -> Response {
  json_response(
    400,
    json.object([#("error", json.string(message))])
    |> json.to_string,
  )
}

/// 500 Internal Server Error response
fn internal_error(message: String) -> Response {
  json_response(
    500,
    json.object([#("error", json.string(message))])
    |> json.to_string,
  )
}
