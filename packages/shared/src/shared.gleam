/// Shared types and functions for boba-raider-8

import gleam/dynamic/decode
import gleam/json

pub type AppError {
  NotFound(String)
  InvalidInput(String)
  Unauthorized(String)
  InternalError(String)
  Unauthorized(String)
}

/// Convert an error to a human-readable message
pub fn error_message(error: AppError) -> String {
  case error {
    NotFound(msg) -> "Not found: " <> msg
    InvalidInput(msg) -> "Invalid input: " <> msg
    Unauthorized(msg) -> "Unauthorized: " <> msg
    InternalError(msg) -> "Internal error: " <> msg
    Unauthorized(msg) -> "Unauthorized: " <> msg
  }
}

/// Boba drink with full details
pub type Drink {
  Drink(
    id: String,
    name: String,
    shop_name: String,
    description: String,
    price: Float,
    image_url: String,
    average_ratings: RatingBreakdown,
  )
}

/// 4-axis boba-specific rating breakdown (1-5 scale)
pub type RatingBreakdown {
  RatingBreakdown(
    taste: Float,
    texture: Float,
    sweetness: Float,
    presentation: Float,
  )
}

/// User's rating with breakdown
pub type Rating {
  Rating(
    id: String,
    drink_id: String,
    user_id: String,
    user_name: String,
    breakdown: RatingBreakdown,
    comment: String,
    created_at: String,
  )
}

/// User's existing rating for a drink (optional)
pub type UserRating {
  UserRating(
    rating: Rating,
  )
}

/// Calculate average rating from breakdown
pub fn average_from_breakdown(breakdown: RatingBreakdown) -> Float {
  let sum = breakdown.taste +. breakdown.texture +. breakdown.sweetness +. breakdown.presentation
  sum /. 4.0
}
