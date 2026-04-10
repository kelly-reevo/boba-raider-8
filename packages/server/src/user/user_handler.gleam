/// HTTP handlers for user endpoints

import gleam/json
import gleam/option.{None, Some}
import user/user.{extract_user_id, profile_to_json}
import user/user_db
import web/server.{type Request, type Response, json_response}

/// GET /api/users/me - Get current authenticated user's profile
/// Returns 200 with user profile and rating counts, or 401 if not authenticated
pub fn get_current_user(request: Request) -> Response {
  case extract_user_id(request.headers) {
    Ok(user_id) -> {
      case user_db.get_user_profile(user_id) {
        Some(profile) -> {
          json_response(
            200,
            profile_to_json(profile)
              |> json.to_string,
          )
        }
        None -> {
          // User ID from token but no profile found
          json_response(
            401,
            json.object([#("error", json.string("Unauthorized"))])
              |> json.to_string,
          )
        }
      }
    }
    Error(_) -> {
      // Missing or invalid Authorization header
      json_response(
        401,
        json.object([#("error", json.string("Unauthorized"))])
          |> json.to_string,
      )
    }
  }
}
