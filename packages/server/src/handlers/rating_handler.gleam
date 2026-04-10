/// HTTP handlers for store ratings

import gleam/dict
import gleam/json
import store/rating_store.{type RatingStore}
import web/server.{type Request, type Response, json_response, text_response}

/// Extract user_id from X-User-Id header (simplified auth)
fn get_current_user_id(request: Request) -> Result(String, Nil) {
  dict.get(request.headers, "x-user-id")
}

/// DELETE /api/ratings/store/:rating_id
/// Users can only delete their own ratings
pub fn delete_store_rating(
  store: RatingStore,
  request: Request,
  rating_id: String,
) -> Response {
  // Verify user is authenticated
  let user_id_result = get_current_user_id(request)

  case user_id_result {
    Error(Nil) -> {
      json_response(
        401,
        json.object([#("error", json.string("Unauthorized"))])
        |> json.to_string,
      )
    }

    Ok(current_user_id) -> {
      // Fetch the rating
      case rating_store.get(store, rating_id) {
        Error(Nil) -> {
          // Rating not found
          json_response(
            404,
            json.object([#("error", json.string("Rating not found"))])
            |> json.to_string,
          )
        }

        Ok(rating_item) -> {
          // Verify ownership
          case rating_item.user_id == current_user_id {
            False -> {
              // User does not own this rating
              json_response(
                403,
                json.object([#("error", json.string("Can only delete own ratings"))])
                |> json.to_string,
              )
            }

            True -> {
              // Delete the rating and trigger recalculation
              let deleted = rating_store.delete(store, rating_id)

              case deleted {
                True -> {
                  // Store average recalculation happens implicitly via store
                  // Return 204 No Content on success
                  text_response(204, "")
                }

                False -> {
                  // Should not happen since we checked existence
                  json_response(
                    500,
                    json.object([#("error", json.string("Failed to delete rating"))])
                    |> json.to_string,
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
