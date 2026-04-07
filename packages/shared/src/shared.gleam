/// Shared types and functions for boba-raider-8

import gleam/dynamic/decode

pub type AppError {
  NotFound(String)
  InvalidInput(String)
  InternalError(String)
}

/// Convert an error to a human-readable message
pub fn error_message(error: AppError) -> String {
  case error {
    NotFound(msg) -> "Not found: " <> msg
    InvalidInput(msg) -> "Invalid input: " <> msg
    InternalError(msg) -> "Internal error: " <> msg
  }
}

pub type Store {
  Store(
    id: String,
    name: String,
    address: String,
    description: String,
    average_rating: Float,
    total_ratings: Int,
  )
}

pub type Drink {
  Drink(
    id: String,
    store_id: String,
    name: String,
    description: String,
    price_cents: Int,
    average_rating: Float,
    total_ratings: Int,
  )
}

pub fn store_decoder() -> decode.Decoder(Store) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use address <- decode.field("address", decode.string)
  use description <- decode.field("description", decode.string)
  use average_rating <- decode.field("average_rating", decode.float)
  use total_ratings <- decode.field("total_ratings", decode.int)
  decode.success(Store(
    id: id,
    name: name,
    address: address,
    description: description,
    average_rating: average_rating,
    total_ratings: total_ratings,
  ))
}

pub fn drink_decoder() -> decode.Decoder(Drink) {
  use id <- decode.field("id", decode.string)
  use store_id <- decode.field("store_id", decode.string)
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.string)
  use price_cents <- decode.field("price_cents", decode.int)
  use average_rating <- decode.field("average_rating", decode.float)
  use total_ratings <- decode.field("total_ratings", decode.int)
  decode.success(Drink(
    id: id,
    store_id: store_id,
    name: name,
    description: description,
    price_cents: price_cents,
    average_rating: average_rating,
    total_ratings: total_ratings,
  ))
}

pub fn drinks_decoder() -> decode.Decoder(List(Drink)) {
  decode.list(drink_decoder())
}
