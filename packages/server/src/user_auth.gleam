import gleam/dict
import gleam/string
import web/server.{type Request}

/// Extract the authenticated user ID from the Authorization header.
/// Expects "Bearer <user_id>" format.
pub fn get_user_id(request: Request) -> Result(String, String) {
  case dict.get(request.headers, "authorization") {
    Ok(value) -> parse_bearer_token(value)
    Error(_) -> Error("Missing Authorization header")
  }
}

fn parse_bearer_token(header: String) -> Result(String, String) {
  case string.split(header, " ") {
    ["Bearer", token] if token != "" -> Ok(token)
    _ -> Error("Invalid Authorization header format")
  }
}
