/// Drink ratings API handlers
/// DELETE /api/ratings/drink/:rating_id - Delete own rating

import gleam/dict
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/string
import shared.{type AppError, type Rating, type RatingId, type UserId, Forbidden, NotFound}
import store/ratings_store.{type RatingsTable}
import web/server.{type Request, type Response, json_response}

/// Parse rating_id from URL path
fn parse_rating_id(path: String) -> Result(RatingId, AppError) {
  // Path format: /api/ratings/drink/:rating_id
  case string.split(path, "/") {
    [_, _, _, _, rating_id_str] -> {
      Ok(shared.rating_id_from_string(rating_id_str))
    }
    _ -> Error(NotFound("Invalid rating path"))
  }
}

/// Extract current user from request headers
/// Simplicity bias: Simple header-based auth for now
fn get_current_user_id(request: Request) -> Option(UserId) {
  case dict.get(request.headers, "x-user-id") {
    Ok(user_id_str) -> Some(shared.user_id_from_string(user_id_str))
    Error(_) -> None
  }
}

/// Verify user owns the rating
fn verify_ownership(rating: Rating, user_id: UserId) -> Result(Rating, AppError) {
  let rating_user_str = shared.user_id_to_string(rating.user_id)
  let current_user_str = shared.user_id_to_string(user_id)

  case rating_user_str == current_user_str {
    True -> Ok(rating)
    False -> Error(Forbidden("Can only delete your own ratings"))
  }
}

/// Delete rating handler
/// DELETE /api/ratings/drink/:rating_id
/// Returns: 204 on success, 403 if not owner, 404 if not found
pub fn delete_rating(
  request: Request,
  table: RatingsTable,
) -> Response {
  // Only allow DELETE method
  case request.method {
    "DELETE" -> {
      // Parse rating ID from path
      case parse_rating_id(request.path) {
        Error(err) -> error_response(err)
        Ok(rating_id) -> {
          // Get current user from request
          case get_current_user_id(request) {
            None ->
              json_response(
                401,
                json.object([#("error", json.string("Unauthorized"))])
                |> json.to_string,
              )
            Some(user_id) -> {
              // Look up the rating
              case ratings_store.get_by_id(table, rating_id) {
                None -> error_response(NotFound("Rating not found"))
                Some(rating) -> {
                  // Verify ownership
                  case verify_ownership(rating, user_id) {
                    Error(err) -> error_response(err)
                    Ok(_) -> {
                      // Delete the rating
                      let _ = ratings_store.delete(table, rating_id)

                      // Recalculate drink average (triggers across all axes)
                      let _ =
                        ratings_store.calculate_drink_average(table, rating.drink_id)

                      // Return 204 No Content on success
                      // Per HTTP spec, 204 has empty body
                      server.Response(
                        status: 204,
                        headers: dict.from_list([#(
                          "Content-Type",
                          "application/json",
                        )]),
                        body: "",
                      )
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    _ ->
      json_response(
        405,
        json.object([#("error", json.string("Method not allowed"))])
        |> json.to_string,
      )
  }
}

fn error_response(error: AppError) -> server.Response {
  let status = case error {
    NotFound(_) -> 404
    Forbidden(_) -> 403
    _ -> 400
  }

  json_response(
    status,
    json.object([#("error", json.string(shared.error_message(error)))])
    |> json.to_string,
  )
}
