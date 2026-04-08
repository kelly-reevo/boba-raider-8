import gleam/dict
import gleam/string
import web/server.{type Request}

/// Extract user ID from Authorization header (Bearer token).
/// Returns Error(Nil) if header is missing or malformed.
pub fn get_user_id(request: Request) -> Result(String, Nil) {
  case dict.get(request.headers, "Authorization") {
    Ok(header) ->
      case string.starts_with(header, "Bearer ") {
        True -> {
          let token = string.drop_start(header, 7) |> string.trim
          case token {
            "" -> Error(Nil)
            uid -> Ok(uid)
          }
        }
        False -> Error(Nil)
      }
    Error(_) -> Error(Nil)
  }
}
