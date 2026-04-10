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

// User types

pub type User {
  User(
    id: String,
    username: String,
    email: String,
    avatar_url: String,
    created_at: String,
  )
}

pub type UserStats {
  UserStats(
    total_store_ratings: Int,
    total_drink_ratings: Int,
    average_store_rating: Float,
    average_drink_rating: Float,
  )
}

pub type UserProfile {
  UserProfile(user: User, stats: UserStats)
}

// Rating types

pub type StoreRating {
  StoreRating(
    id: String,
    store_id: String,
    store_name: String,
    rating: Int,
    review: String,
    created_at: String,
  )
}

pub type DrinkRating {
  DrinkRating(
    id: String,
    drink_id: String,
    drink_name: String,
    store_name: String,
    rating: Int,
    review: String,
    created_at: String,
  )
}

// Paginated response

pub type PaginatedResponse(a) {
  PaginatedResponse(
    items: List(a),
    total: Int,
    page: Int,
    per_page: Int,
  )
}

// Profile page types

pub type ProfileTab {
  StoreRatingsTab
  DrinkRatingsTab
}

pub type LoadState(a) {
  Loading
  Empty
  Error(String)
  Populated(a)
}
