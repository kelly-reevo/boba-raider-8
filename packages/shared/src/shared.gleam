/// Shared types and functions for boba-raider-8

import gleam/json.{type Json}

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

// Domain types

pub type UserRole {
  Admin
  Creator
  Regular
}

pub type User {
  User(id: String, role: UserRole)
}

pub type Store {
  Store(
    id: String,
    name: String,
    creator_id: String,
    created_at: String,
  )
}

pub type Drink {
  Drink(
    id: String,
    store_id: String,
    name: String,
    description: String,
    created_at: String,
  )
}

pub type Rating {
  Rating(
    id: String,
    drink_id: String,
    user_id: String,
    score: Int,
    comment: String,
    created_at: String,
  )
}
