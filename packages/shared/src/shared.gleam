/// Shared types and functions for boba-raider-8

import gleam/string

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

/// User representation
pub type User {
  User(id: String, username: String, email: String)
}

/// Authentication token
pub type AuthToken {
  AuthToken(access_token: String, refresh_token: String)
}

/// Authentication response from API
pub type AuthResponse {
  AuthResponse(user: User, token: AuthToken)
}

/// Login request payload
pub type LoginRequest {
  LoginRequest(email: String, password: String)
}

/// Registration request payload
pub type RegisterRequest {
  RegisterRequest(username: String, email: String, password: String)
}

/// Validation result for forms
pub type ValidationError {
  FieldRequired(String)
  InvalidEmail(String)
  PasswordTooShort(String)
  PasswordsDoNotMatch
}

/// Validate email format (basic check)
pub fn validate_email(email: String) -> Result(String, ValidationError) {
  case string.contains(email, "@") {
    True -> Ok(email)
    False -> Error(InvalidEmail(email))
  }
}

/// Validate password length
pub fn validate_password(password: String) -> Result(String, ValidationError) {
  case string.length(password) >= 8 {
    True -> Ok(password)
    False -> Error(PasswordTooShort(password))
  }
}

// Store types for boba shop locations

pub type StoreId {
  StoreId(String)
}

pub type UserId {
  UserId(String)
}

pub type Store {
  Store(
    id: StoreId,
    name: String,
    address: String,
    location: Location,
    phone: Option(String),
    hours: Option(String),
    description: Option(String),
    image_url: Option(String),
    created_by: UserId,
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

pub type Location {
  Location(lat: Float, lng: Float)
}

pub type Timestamp {
  Timestamp(String)
}

// Store input types for creating/updating

pub type CreateStore {
  CreateStore(
    name: String,
    address: String,
    lat: Float,
    lng: Float,
    phone: Option(String),
    hours: Option(String),
    description: Option(String),
    image_url: Option(String),
    created_by: UserId,
  )
}

pub type UpdateStore {
  UpdateStore(
    name: Option(String),
    address: Option(String),
    lat: Option(Float),
    lng: Option(Float),
    phone: Option(Option(String)),
    hours: Option(Option(String)),
    description: Option(Option(String)),
    image_url: Option(Option(String)),
  )
}
