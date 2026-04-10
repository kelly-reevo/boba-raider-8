/// Authentication and authorization utilities

import gleam/dict.{type Dict}
import gleam/string
import shared.{type User, User, Admin, Regular}

/// Extract user from request headers (simplified token-based auth)
/// In production, this would validate JWT tokens
pub fn get_current_user(headers: Dict(String, String)) -> Result(User, String) {
  case dict.get(headers, "authorization") {
    Ok(token) -> parse_token(token)
    Error(_) -> Error("Missing authorization header")
  }
}

/// Parse token to extract user info
/// Format: "Bearer user_id:role" (simplified for this implementation)
fn parse_token(token: String) -> Result(User, String) {
  case string.starts_with(token, "Bearer ") {
    True -> {
      let parts = string.drop_start(token, 7)
        |> string.split(":")

      case parts {
        [user_id, role_str] -> {
          let role = case role_str {
            "admin" -> Admin
            _ -> Regular
          }
          Ok(User(
            id: user_id,
            email: user_id <> "@example.com", // Simplified
            role: role,
          ))
        }
        _ -> Error("Invalid token format")
      }
    }
    False -> Error("Invalid authorization format")
  }
}

/// Check if user is admin
pub fn is_admin(user: User) -> Bool {
  case user.role {
    Admin -> True
    Regular -> False
  }
}

/// Check if user can modify store (owner or admin)
pub fn can_modify_store(user: User, creator_id: String) -> Bool {
  case user.role {
    Admin -> True
    Regular -> user.id == creator_id
  }
}
