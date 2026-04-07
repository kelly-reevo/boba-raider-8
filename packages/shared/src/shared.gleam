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

/// Authenticated user
pub type User {
  User(id: String, username: String, email: String)
}

/// Response from login/register endpoints
pub type AuthResponse {
  AuthResponse(token: String, user: User)
}
