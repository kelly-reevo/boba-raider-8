/// Shared types and functions for boba-raider-8

import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}

pub type AppError {
  NotFound(String)
  InvalidInput(String)
  InternalError(String)
  Unauthorized(String)
}

/// Convert an error to a human-readable message
pub fn error_message(error: AppError) -> String {
  case error {
    NotFound(msg) -> "Not found: " <> msg
    InvalidInput(msg) -> "Invalid input: " <> msg
    InternalError(msg) -> "Internal error: " <> msg
    Unauthorized(msg) -> "Unauthorized: " <> msg
  }
}

// === Store Types ===

pub type Store {
  Store(id: String, name: String)
}

pub fn store_to_json(store: Store) -> Json {
  json.object([
    #("id", json.string(store.id)),
    #("name", json.string(store.name)),
  ])
}

// === Drink Types ===

pub type Drink {
  Drink(
    id: String,
    name: String,
    tea_type: String,
    image_url: Option(String),
    store: Store,
  )
}

pub fn drink_to_json(drink: Drink) -> Json {
  json.object([
    #("id", json.string(drink.id)),
    #("name", json.string(drink.name)),
    #("tea_type", json.string(drink.tea_type)),
    #("image_url", option_to_json(drink.image_url, json.string)),
    #("store", store_to_json(drink.store)),
  ])
}

// === Drink Rating Types ===

pub type DrinkRating {
  DrinkRating(
    id: String,
    overall_score: Float,
    sweetness: Float,
    boba_texture: Float,
    tea_strength: Float,
    review_text: Option(String),
    created_at: String,
    updated_at: String,
    drink: Drink,
  )
}

pub fn drink_rating_to_json(rating: DrinkRating) -> Json {
  json.object([
    #("id", json.string(rating.id)),
    #("overall_score", json.float(rating.overall_score)),
    #("sweetness", json.float(rating.sweetness)),
    #("boba_texture", json.float(rating.boba_texture)),
    #("tea_strength", json.float(rating.tea_strength)),
    #("review_text", option_to_json(rating.review_text, json.string)),
    #("created_at", json.string(rating.created_at)),
    #("updated_at", json.string(rating.updated_at)),
    #("drink", drink_to_json(rating.drink)),
  ])
}

// === Pagination Types ===

pub type PaginationMeta {
  PaginationMeta(total: Int, page: Int, limit: Int, total_pages: Int)
}

pub fn pagination_meta_to_json(meta: PaginationMeta) -> Json {
  json.object([
    #("total", json.int(meta.total)),
    #("page", json.int(meta.page)),
    #("limit", json.int(meta.limit)),
    #("total_pages", json.int(meta.total_pages)),
  ])
}

pub type PaginatedResponse(a) {
  PaginatedResponse(data: List(a), meta: PaginationMeta)
}

pub fn paginated_response_to_json(
  response: PaginatedResponse(a),
  item_to_json: fn(a) -> Json,
) -> Json {
  json.object([
    #("data", json.array(response.data, item_to_json)),
    #("meta", pagination_meta_to_json(response.meta)),
  ])
}

// === Helper Functions ===

fn option_to_json(option: Option(a), to_json_fn: fn(a) -> Json) -> Json {
  case option {
    Some(value) -> to_json_fn(value)
    None -> json.null()
  }
}
