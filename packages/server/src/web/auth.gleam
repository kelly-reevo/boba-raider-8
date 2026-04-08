import gleam/dict
import gleam/string
import shared
import web/server.{type Request}

/// Extract user_id from Authorization header (Bearer token).
/// Returns the user_id or an Unauthorized error.
pub fn get_user_id(request: Request) -> Result(String, shared.AppError) {
  case dict.get(request.headers, "authorization") {
    Ok(value) ->
      case string.starts_with(value, "Bearer ") {
        True -> {
          let token = string.drop_start(value, 7) |> string.trim
          case token {
            "" -> Error(shared.Unauthorized("Missing token"))
            uid -> Ok(uid)
          }
        }
        False -> Error(shared.Unauthorized("Invalid authorization format"))
      }
    Error(_) -> Error(shared.Unauthorized("Missing authorization header"))
  }
}
