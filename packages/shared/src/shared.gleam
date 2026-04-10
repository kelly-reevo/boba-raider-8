/// Shared types and functions for boba-raider-8

import gleam/json.{type Json}
import gleam/option.{type Option}

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

/// User domain type
pub type User {
  User(
    id: String,
    username: String,
    created_at: String,
    updated_at: String,
  )
}

pub fn user_to_json(user: User) -> Json {
  json.object([
    #("id", json.string(user.id)),
    #("username", json.string(user.username)),
    #("created_at", json.string(user.created_at)),
    #("updated_at", json.string(user.updated_at)),
  ])
}

/// Store domain type
pub type Store {
  Store(
    id: String,
    name: String,
    created_at: String,
    updated_at: String,
  )
}

pub fn store_to_json(store: Store) -> Json {
  json.object([
    #("id", json.string(store.id)),
    #("name", json.string(store.name)),
    #("created_at", json.string(store.created_at)),
    #("updated_at", json.string(store.updated_at)),
  ])
}

/// Rating domain type
/// One rating per user per store (upsert on duplicate)
pub type Rating {
  Rating(
    id: String,
    store_id: String,
    user_id: String,
    overall_score: Int,
    review_text: Option(String),
    created_at: String,
    updated_at: String,
  )
}

/// Rating with embedded user info for API responses
pub type RatingWithUser {
  RatingWithUser(
    id: String,
    store_id: String,
    user_id: String,
    user: User,
    overall_score: Int,
    review_text: Option(String),
    created_at: String,
    updated_at: String,
  )
}

pub fn rating_with_user_to_json(rating: RatingWithUser) -> Json {
  let review_text_field = case rating.review_text {
    option.Some(text) -> #("review_text", json.string(text))
    option.None -> #("review_text", json.null())
  }

  json.object([
    #("id", json.string(rating.id)),
    #("store_id", json.string(rating.store_id)),
    #("user_id", json.string(rating.user_id)),
    #("user", user_to_json(rating.user)),
    #("overall_score", json.int(rating.overall_score)),
    review_text_field,
    #("created_at", json.string(rating.created_at)),
    #("updated_at", json.string(rating.updated_at)),
  ])
}

/// Create rating request body
pub type CreateRatingRequest {
  CreateRatingRequest(
    overall_score: Int,
    review_text: Option(String),
  )
}

/// Validate overall_score is between 1-5
pub fn validate_overall_score(score: Int) -> Result(Int, AppError) {
  case score >= 1 && score <= 5 {
    True -> Ok(score)
    False -> Error(InvalidInput("overall_score must be between 1 and 5"))
  }
}
