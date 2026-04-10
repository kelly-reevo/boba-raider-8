import gleam/dict
import web/server.{type Request, type Response, json_response}

/// Extract user_id from Authorization header.
/// Expects header format: "Bearer user_<id>"
/// Returns 401 response if header is missing or invalid.
pub fn require_user(request: Request) -> Result(String, Response) {
  case dict.get(request.headers, "authorization") {
    Ok(auth_header) -> parse_auth_header(auth_header)
    Error(_) -> Error(unauthorized_response())
  }
}

fn parse_auth_header(header: String) -> Result(String, Response) {
  case header {
    "Bearer user_" <> user_id -> Ok("user_" <> user_id)
    _ -> Error(unauthorized_response())
  }
}

fn unauthorized_response() -> Response {
  json_response(
    401,
    "{\"error\":\"Unauthorized\"}",
  )
}
