/// Rating domain re-exports from shared module
/// This module provides a convenient alias to shared rating types

// Re-export all rating-related types from shared
pub type Rating = shared.Rating
pub type RatingScores = shared.RatingScores
pub type CreateRatingInput = shared.CreateRatingInput
pub type UserSummary = shared.UserSummary

// Re-export validation functions
pub fn is_valid_score(score: Int) -> Bool {
  shared.is_valid_score(score)
}

pub fn is_valid_review_text(text: Option(String)) -> Bool {
  shared.is_valid_review_text(text)
}

// Aliases for convenience
import gleam/option.{type Option}
import shared
