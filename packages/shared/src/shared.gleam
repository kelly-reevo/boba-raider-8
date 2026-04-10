/// Shared types and functions for boba-raider-8

import gleam/int
import gleam/option.{type Option}
import gleam/string

pub type AppError {
  NotFound(String)
  InvalidInput(String)
  InternalError(String)
  DuplicateError(String)
}

/// Rating scores for boba drinks - 1-5 scale for each axis
pub type RatingScores {
  RatingScores(
    overall_score: Int,
    sweetness: Int,
    boba_texture: Int,
    tea_strength: Int,
  )
}

/// Minimal user summary for embedding in responses
pub type UserSummary {
  UserSummary(id: String, username: String)
}

/// A drink rating with review from a user
pub type Rating {
  Rating(
    id: String,
    drink_id: String,
    user_id: String,
    scores: RatingScores,
    review_text: Option(String),
    created_at: String,
    updated_at: String,
  )
}

/// Input payload for creating a rating
pub type CreateRatingInput {
  CreateRatingInput(
    overall_score: Int,
    sweetness: Int,
    boba_texture: Int,
    tea_strength: Int,
    review_text: Option(String),
  )
}

/// Rating-specific validation errors
pub type RatingError {
  InvalidScore(field: String, value: Int)
  DuplicateRating
  DrinkNotFound
  UserNotFound
  InvalidReviewLength
  RatingStoreError(String)
}

/// Convert an error to a human-readable message
pub fn error_message(error: AppError) -> String {
  case error {
    NotFound(msg) -> "Not found: " <> msg
    InvalidInput(msg) -> "Invalid input: " <> msg
    InternalError(msg) -> "Internal error: " <> msg
    DuplicateError(msg) -> "Duplicate: " <> msg
  }
}

/// Convert rating error to message
pub fn rating_error_message(error: RatingError) -> String {
  case error {
    InvalidScore(field, value) ->
      "Invalid score for " <> field <> ": " <> int.to_string(value) <> " (must be 1-5)"
    DuplicateRating -> "User has already rated this drink"
    DrinkNotFound -> "Drink not found"
    UserNotFound -> "User not found"
    InvalidReviewLength -> "Review text must be 1000 characters or less"
    RatingStoreError(msg) -> "Store error: " <> msg
  }
}

/// Score range validation (1-5)
pub fn is_valid_score(score: Int) -> Bool {
  score >= 1 && score <= 5
}

/// Review text validation (optional, max 1000 chars if present)
pub fn is_valid_review_text(text: Option(String)) -> Bool {
  case text {
    option.None -> True
    option.Some(t) -> string.length(t) <= 1000
  }
}

/// Validate all rating scores
/// Returns field name on error for 422 response
pub fn validate_scores(input: CreateRatingInput) -> Result(Nil, String) {
  case is_valid_score(input.overall_score) {
    False -> Error("overall_score")
    True ->
      case is_valid_score(input.sweetness) {
        False -> Error("sweetness")
        True ->
          case is_valid_score(input.boba_texture) {
            False -> Error("boba_texture")
            True ->
              case is_valid_score(input.tea_strength) {
                False -> Error("tea_strength")
                True -> Ok(Nil)
              }
          }
      }
  }
}

/// Validate complete rating input
/// Returns field name or "review_text" on error
pub fn validate_rating_input(input: CreateRatingInput) -> Result(Nil, String) {
  case validate_scores(input) {
    Error(field) -> Error(field)
    Ok(_) ->
      case is_valid_review_text(input.review_text) {
        False -> Error("review_text")
        True -> Ok(Nil)
      }
  }
}
