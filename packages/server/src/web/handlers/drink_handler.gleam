/// Drink Handler - HTTP request handlers for drink endpoints

import gleam/json
import gleam/list
import gleam/option.{None, Some, type Option}
import gleam/string
import drink_store.{type DrinkStore}
import rating_service.{type RatingService}
import services/drink_service
import store/store_data_access as store_access
import web/server

/// Response shape for a drink with aggregates
pub type DrinkResponse {
  DrinkResponse(
    id: String,
    name: String,
    description: Option(String),
    base_tea_type: Option(String),
    price: Option(Float),
    aggregates: AggregatesResponse,
  )
}

/// Aggregates sub-object in response
pub type AggregatesResponse {
  AggregatesResponse(overall_rating: Float, count: Int)
}

/// Convert DrinkOutput to response shape
fn to_response(drink: drink_service.DrinkOutput) -> DrinkResponse {
  let overall = case drink.avg_overall {
    Some(rating) -> rating
    None -> 0.0
  }

  DrinkResponse(
    id: drink.id,
    name: drink.name,
    description: drink.description,
    base_tea_type: drink.base_tea_type,
    price: drink.price,
    aggregates: AggregatesResponse(
      overall_rating: overall,
      count: drink.rating_count,
    ),
  )
}

/// Encode a DrinkResponse to JSON
fn encode_drink_response(drink: DrinkResponse) -> json.Json {
  json.object([
    #("id", json.string(drink.id)),
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
      #("overall_rating", json.float(drink.aggregates.overall_rating)),
      #("count", json.int(drink.aggregates.count)),
    ])),
  ])
}

/// Encode a list of drinks to JSON response
fn encode_drinks_response(drinks: List(DrinkResponse)) -> json.Json {
  json.object([
    #("drinks", json.array(drinks, of: encode_drink_response)),
  ])
}

/// Encode error response
fn encode_error_response(message: String) -> json.Json {
  json.object([#("error", json.string(message))])
}

/// Extract store ID from path /api/stores/:id/drinks
fn extract_store_id(path: String) -> Option(String) {
  let parts = path |> string.split("/")
  case parts {
    ["", "api", "stores", store_id, "drinks"] -> Some(store_id)
    _ -> None
  }
}

/// Handler for GET /api/stores/:id/drinks
pub fn list_drinks_by_store(
  drink_store: DrinkStore,
  store_state: store_access.StoreState,
  rating_service: RatingService,
  path: String,
) -> server.Response {
  case extract_store_id(path) {
    None -> {
      server.json_response(
        404,
        encode_error_response("Not found") |> json.to_string,
      )
    }
    Some(store_id) -> {
      case drink_service.list_drinks_by_store(
        drink_store,
        store_state,
        rating_service,
        store_id,
      ) {
        Error(drink_service.NotFoundError(_)) -> {
          server.json_response(
            404,
            encode_error_response("Store not found") |> json.to_string,
          )
        }
        Error(_) -> {
          server.json_response(
            500,
            encode_error_response("Internal error") |> json.to_string,
          )
        }
        Ok(drinks) -> {
          let response_drinks = drinks |> list.map(to_response)
          server.json_response(
            200,
            encode_drinks_response(response_drinks) |> json.to_string,
          )
        }
      }
    }
  }
}
