/// Shared types and functions for boba-raider-8

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

/// Rating values use 1-5 integer scale, 0 means unset
pub type RatingSubmission {
  RatingSubmission(
    sweetness: Int,
    boba_texture: Int,
    tea_strength: Int,
    overall: Int,
  )
}

pub fn empty_rating() -> RatingSubmission {
  RatingSubmission(sweetness: 0, boba_texture: 0, tea_strength: 0, overall: 0)
}

pub fn is_rating_complete(rating: RatingSubmission) -> Bool {
  rating.sweetness > 0
  && rating.boba_texture > 0
  && rating.tea_strength > 0
  && rating.overall > 0
}
