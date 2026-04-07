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

/// A boba store with aggregated rating data
pub type Store {
  Store(
    id: String,
    name: String,
    address: String,
    description: String,
    average_rating: Float,
    rating_count: Int,
  )
}

pub fn store_decoder() -> decode.Decoder(Store) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use address <- decode.field("address", decode.string)
  use description <- decode.field("description", decode.string)
  use average_rating <- decode.field("average_rating", decode.float)
  use rating_count <- decode.field("rating_count", decode.int)
  decode.success(Store(
    id: id,
    name: name,
    address: address,
    description: description,
    average_rating: average_rating,
    rating_count: rating_count,
  ))
}

pub fn stores_response_decoder() -> decode.Decoder(List(Store)) {
  use stores <- decode.field("stores", decode.list(store_decoder()))
  decode.success(stores)
}
