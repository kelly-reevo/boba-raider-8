/// Drink ratings handlers
/// PATCH /api/ratings/drink/:rating_id - Update existing rating

import gleam/dict
import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/string
import shared.{
  type Rating, type UpdateRatingRequest, UpdateRatingRequest,
  rating_to_json, validate_update_request,
}
import store.{type Store}
import web/server.{type Request, type Response, json_response}

/// Build a decoder for UpdateRatingRequest using the field/success pattern
fn update_rating_request_decoder() {
  // Use the use-based decoder pattern
  use overall_score <- decode.field(
    "overall_score",
    decode.optional(decode.int),
  )
  use sweetness <- decode.field("sweetness", decode.optional(decode.int))
  use boba_texture <- decode.field("boba_texture", decode.optional(decode.int))
  use tea_strength <- decode.field("tea_strength", decode.optional(decode.int))
  use review_text <- decode.field("review_text", decode.optional(decode.string))

  decode.success(UpdateRatingRequest(
    overall_score: overall_score,
    sweetness: sweetness,
    boba_texture: boba_texture,
    tea_strength: tea_strength,
    review_text: review_text,
  ))
}

/// Parse update rating request from JSON body
fn parse_update_request(body: String) -> Result(UpdateRatingRequest, String) {
  // json.parse now takes both the string and the decoder
  case json.parse(body, using: update_rating_request_decoder()) {
    Ok(req) -> Ok(req)
    Error(_) -> Error("Invalid JSON or field types")
  }
}

/// Extract current user ID from request (simplified - from header)
fn get_current_user_id(request: Request) -> Option(String) {
  case dict.get(request.headers, "x-user-id") {
    Ok(user_id) if user_id != "" -> Some(user_id)
    _ -> None
  }
}

/// Extract rating ID from path /api/ratings/drink/:rating_id
fn extract_rating_id(path: String) -> Option(String) {
  case string.split(path, "/") {
    ["", "api", "ratings", "drink", rating_id] -> Some(rating_id)
    _ -> None
  }
}

/// Apply updates to existing rating
fn apply_updates(rating: Rating, req: UpdateRatingRequest) -> Rating {
  shared.Rating(
    id: rating.id,
    user_id: rating.user_id,
    drink_id: rating.drink_id,
    overall_score: option.unwrap(req.overall_score, rating.overall_score),
    sweetness: option.unwrap(req.sweetness, rating.sweetness),
    boba_texture: option.unwrap(req.boba_texture, rating.boba_texture),
    tea_strength: option.unwrap(req.tea_strength, rating.tea_strength),
    review_text: option.unwrap(req.review_text, rating.review_text),
    created_at: rating.created_at,
    updated_at: "2026-04-10T00:00:00Z",
  )
}

/// PATCH /api/ratings/drink/:rating_id
/// User can modify any rating axis or review text for their own rating
pub fn update_rating(
  request: Request,
  store: Store,
) -> Response {
  // Extract rating ID from path
  let rating_id_result = extract_rating_id(request.path)

  case rating_id_result {
    None ->
      json_response(
        404,
        json.object([#("error", json.string("Rating not found"))])
        |> json.to_string,
      )
    Some(rating_id) -> {
      // Get current user
      case get_current_user_id(request) {
        None ->
          json_response(
            403,
            json.object([#("error", json.string("Authentication required"))])
            |> json.to_string,
          )
        Some(current_user) -> {
          // Look up existing rating
          case store.get_rating(store, rating_id) {
            None ->
              json_response(
                404,
                json.object([#("error", json.string("Rating not found"))])
                |> json.to_string,
              )
            Some(existing_rating) -> {
              // Check ownership - user can only update their own ratings
              case existing_rating.user_id == current_user {
                False ->
                  json_response(
                    403,
                    json.object([#("error", json.string("Cannot modify another user's rating"))])
                    |> json.to_string,
                  )
                True -> {
                  // Parse request body
                  case parse_update_request(request.body) {
                    Error(msg) ->
                      json_response(
                        422,
                        json.object([#("error", json.string("Invalid request: " <> msg))])
                        |> json.to_string,
                      )
                    Ok(update_req) -> {
                      // Validate request
                      case validate_update_request(update_req) {
                        Error(msg) ->
                          json_response(
                            422,
                            json.object([#("error", json.string(msg))])
                            |> json.to_string,
                          )
                        Ok(_) -> {
                          // Apply updates and save
                          let updated_rating = apply_updates(existing_rating, update_req)

                          case store.save_rating(store, updated_rating) {
                            Ok(_) -> {
                              json_response(
                                200,
                                json.object([
                                  #("data", rating_to_json(updated_rating)),
                                ])
                                |> json.to_string,
                              )
                            }
                            Error(err) -> {
                              json_response(
                                500,
                                json.object([#("error", json.string(shared.error_message(err)))])
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
          }
        }
      }
    }
  }
}

/// Handle rating-related requests
pub fn handle(
  method: String,
  path: String,
  request: Request,
  store: Store,
) -> Option(Response) {
  case method, string.starts_with(path, "/api/ratings/drink/") {
    "PATCH", True -> Some(update_rating(request, store))
    _, _ -> None
  }
}
