/// Shared types and functions for boba-raider-8

import gleam/int
import gleam/string

pub type AppError {
  NotFound(String)
  InvalidInput(String)
  Unauthorized(String)
  InternalError(String)
  Forbidden(String)
}

/// Convert an error to a human-readable message
pub fn error_message(error: AppError) -> String {
  case error {
    NotFound(msg) -> "Not found: " <> msg
    InvalidInput(msg) -> "Invalid input: " <> msg
    Unauthorized(msg) -> "Unauthorized: " <> msg
    InternalError(msg) -> "Internal error: " <> msg
    Forbidden(msg) -> "Forbidden: " <> msg
  }
}

// Rating domain types

pub type RatingId {
  RatingId(String)
}

pub type UserId {
  UserId(String)
}

pub type DrinkId {
  DrinkId(String)
}

pub type Rating {
  Rating(
    id: RatingId,
    user_id: UserId,
    drink_id: DrinkId,
    value: Int,
  )
}

/// Extract string from RatingId
pub fn rating_id_to_string(rating_id: RatingId) -> String {
  let RatingId(id) = rating_id
  id
}

/// Create RatingId from string
pub fn rating_id_from_string(id: String) -> RatingId {
  RatingId(id)
}

/// Extract string from UserId
pub fn user_id_to_string(user_id: UserId) -> String {
  let UserId(id) = user_id
  id
}

/// Create UserId from string
pub fn user_id_from_string(id: String) -> UserId {
  UserId(id)
}

/// Extract string from DrinkId
pub fn drink_id_to_string(drink_id: DrinkId) -> String {
  let DrinkId(id) = drink_id
  id
}

/// Create DrinkId from string
pub fn drink_id_from_string(id: String) -> DrinkId {
  DrinkId(id)
}
