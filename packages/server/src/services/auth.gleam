/// Authentication service - Unit 2 dependency
/// Handles user context extraction from requests

import gleam/dict.{type Dict}

/// User context extracted from request
pub type UserContext {
  UserContext(user_id: String)
}

/// Extract user context from request headers
/// Looks for X-User-Id header (set by auth middleware/gateway)
pub fn extract_user(headers: Dict(String, String)) -> Result(UserContext, String) {
  case dict.get(headers, "x-user-id") {
    Ok(user_id) -> Ok(UserContext(user_id: user_id))
    Error(_) ->
      Error("Missing authentication: X-User-Id header required")
  }
}

/// Get user ID from context
pub fn user_id(ctx: UserContext) -> String {
  ctx.user_id
}
