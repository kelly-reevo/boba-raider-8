/// Shared types and functions for boba-raider-8

import gleam/json.{type Json}

pub type AppError {
  NotFound(String)
  InvalidInput(String)
  Unauthorized(String)
  InternalError(String)
  Conflict(String)
  Unauthorized(String)
}

/// Convert an error to a human-readable message
pub fn error_message(error: AppError) -> String {
  case error {
    NotFound(msg) -> "Not found: " <> msg
    InvalidInput(msg) -> "Invalid input: " <> msg
    Unauthorized(msg) -> "Unauthorized: " <> msg
    InternalError(msg) -> "Internal error: " <> msg
    Conflict(msg) -> "Conflict: " <> msg
    Unauthorized(msg) -> "Unauthorized: " <> msg
  }
}

/// User role for authorization
pub type UserRole {
  Regular
  Admin
}

/// User entity
pub type User {
  User(
    id: String,
    email: String,
    role: UserRole,
  )
}

/// Boba store entity
pub type Store {
  Store(
    id: String,
    name: String,
    address: String,
    phone: String,
    hours: String,
    description: String,
    image_url: String,
    creator_id: String,
    created_at: String,
    updated_at: String,
  )
}

/// JSON encoder for Store
pub fn store_to_json(store: Store) -> Json {
  json.object([
    #("id", json.string(store.id)),
    #("name", json.string(store.name)),
    #("address", json.string(store.address)),
    #("phone", json.string(store.phone)),
    #("hours", json.string(store.hours)),
    #("description", json.string(store.description)),
    #("image_url", json.string(store.image_url)),
    #("creator_id", json.string(store.creator_id)),
    #("created_at", json.string(store.created_at)),
    #("updated_at", json.string(store.updated_at)),
  ])
}

/// Partial update fields for Store (all optional)
pub type StoreUpdate {
  StoreUpdate(
    name: Option(String),
    address: Option(String),
    phone: Option(String),
    hours: Option(String),
    description: Option(String),
    image_url: Option(String),
  )
}

/// Option type for partial updates
pub type Option(a) {
  Some(a)
  None
}
