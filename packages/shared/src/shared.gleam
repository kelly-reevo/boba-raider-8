/// Shared types and functions for boba-raider-8

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

/// A rating for a boba drink with boba-specific scoring dimensions
pub type Rating {
  Rating(
    id: String,
    drink_id: String,
    user_id: String,
    sweetness: Int,
    texture: Int,
    flavor: Int,
    overall: Int,
    review: String,
  )
}

/// Aggregated ratings for a drink
pub type AggregatedRating {
  AggregatedRating(
    drink_id: String,
    avg_sweetness: Float,
    avg_texture: Float,
    avg_flavor: Float,
    avg_overall: Float,
    count: Int,
  )
}
