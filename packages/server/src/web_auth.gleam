/// Authentication module (unit-17)
/// Extracts and validates user authentication from requests

import gleam/dict.{type Dict}
import gleam/option.{type Option, None, Some}
import gleam/result
import shared.{Unauthorized}

pub type User {
  User(id: String, username: String)
}

/// Extract bearer token from Authorization header
pub fn extract_token(headers: Dict(String, String)) -> Option(String) {
  case dict.get(headers, "authorization") {
    Ok(auth_header) -> {
      case auth_header {
        "Bearer " <> token -> Some(token)
        _ -> None
      }
    }
    Error(_) -> None
  }
}

/// Authenticate user from request headers
/// Returns user if valid, error if not authenticated
pub fn authenticate_user(
  headers: Dict(String, String),
) -> Result(User, shared.AppError) {
  case extract_token(headers) {
    Some(token) -> {
      // Stub: validate token and return user
      // In production, this validates against database/cache
      case token {
        "valid-token" -> Ok(User(id: "user-1", username: "testuser"))
        _ -> Error(Unauthorized("Invalid authentication token"))
      }
    }
    None -> Error(Unauthorized("Missing authentication token"))
  }
}

/// Get current authenticated user ID from headers
pub fn current_user_id(headers: Dict(String, String)) -> Result(String, shared.AppError) {
  authenticate_user(headers)
  |> result.map(fn(user) { user.id })
}
