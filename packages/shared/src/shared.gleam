/// Shared types and functions for boba-raider-8

import gleam/string

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
