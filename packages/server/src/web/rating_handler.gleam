/// HTTP handlers for drink rating endpoints

import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/string
import rating_store.{type RatingStore}
import shared.{type CreateRatingInput, type Rating, type UserSummary}
import web/server.{type Request, type Response, json_response}

/// Parse create rating request body using JSON decoder
fn parse_create_input(
  body: String,
) -> Result(CreateRatingInput, #(String, String)) {
  // Create decoder for rating input
  let input_decoder = {
    use overall_score <- decode.field("overall_score", decode.int)
    use sweetness <- decode.field("sweetness", decode.int)
    use boba_texture <- decode.field("boba_texture", decode.int)
    use tea_strength <- decode.field("tea_strength", decode.int)
    use review_text <- decode.optional_field("review_text", None, decode.optional(decode.string))

    decode.success(shared.CreateRatingInput(
      overall_score:,
      sweetness:,
      boba_texture:,
      tea_strength:,
      review_text:,
    ))
  }

  case json.parse(body, using: input_decoder) {
    Ok(input) -> validate_input(input)
    Error(json.UnexpectedEndOfInput) -> Error(#("body", "unexpected end of input"))
    Error(json.UnexpectedByte(b)) -> Error(#("body", "unexpected byte: " <> b))
    Error(json.UnexpectedSequence(s)) -> Error(#("body", "unexpected sequence: " <> s))
    Error(json.UnableToDecode(_)) -> Error(#("body", "unable to decode JSON"))
  }
}

/// Validate the parsed input
fn validate_input(
  input: CreateRatingInput,
) -> Result(CreateRatingInput, #(String, String)) {
  case shared.is_valid_score(input.overall_score) {
    False -> Error(#("overall_score", "must be between 1 and 5"))
    True ->
      case shared.is_valid_score(input.sweetness) {
        False -> Error(#("sweetness", "must be between 1 and 5"))
        True ->
          case shared.is_valid_score(input.boba_texture) {
            False -> Error(#("boba_texture", "must be between 1 and 5"))
            True ->
              case shared.is_valid_score(input.tea_strength) {
                False -> Error(#("tea_strength", "must be between 1 and 5"))
                True ->
                  case shared.is_valid_review_text(input.review_text) {
                    False -> Error(#("review_text", "must be 1000 characters or less"))
                    True -> Ok(input)
                  }
              }
          }
      }
  }
}

/// Generate simple ID for rating
@external(erlang, "erlang", "unique_integer")
fn unique_integer() -> Int

fn generate_id() -> String {
  "rating_" <> int.to_string(unique_integer())
}

/// Get current timestamp in milliseconds
@external(erlang, "erlang", "system_time")
fn system_time_millis(unit: Int) -> Int

const millisecond = 1000

fn now_iso8601() -> String {
  int.to_string(system_time_millis(millisecond))
}

/// Create a new rating record
fn create_rating_record(
  drink_id: String,
  user_id: String,
  input: CreateRatingInput,
) -> Rating {
  let now = now_iso8601()
  shared.Rating(
    id: generate_id(),
    drink_id:,
    user_id:,
    scores: shared.RatingScores(
      overall_score: input.overall_score,
      sweetness: input.sweetness,
      boba_texture: input.boba_texture,
      tea_strength: input.tea_strength,
    ),
    review_text: input.review_text,
    created_at: now,
    updated_at: now,
  )
}

/// Serialize rating to JSON
fn rating_to_json(rating: Rating, user: UserSummary) -> json.Json {
  json.object([
    #("id", json.string(rating.id)),
    #("drink_id", json.string(rating.drink_id)),
    #("user_id", json.string(rating.user_id)),
    #("user", json.object([
      #("id", json.string(user.id)),
      #("username", json.string(user.username)),
    ])),
    #("overall_score", json.int(rating.scores.overall_score)),
    #("sweetness", json.int(rating.scores.sweetness)),
    #("boba_texture", json.int(rating.scores.boba_texture)),
    #("tea_strength", json.int(rating.scores.tea_strength)),
    #("review_text", case rating.review_text {
      Some(t) -> json.string(t)
      None -> json.null()
    }),
    #("created_at", json.string(rating.created_at)),
    #("updated_at", json.string(rating.updated_at)),
  ])
}

/// Build 422 validation error response
fn validation_error_response(field: String, message: String) -> Response {
  json_response(
    422,
    json.object([
      #("error", json.string("Validation error")),
      #("field", json.string(field)),
      #("message", json.string(message)),
    ])
    |> json.to_string,
  )
}

/// Build 404 not found response
fn not_found_response(resource: String) -> Response {
  json_response(
    404,
    json.object([#("error", json.string(resource <> " not found"))])
    |> json.to_string,
  )
}

/// Build 409 duplicate rating response
fn duplicate_rating_response() -> Response {
  json_response(
    422,
    json.object([
      #("error", json.string("Validation error")),
      #("field", json.string("rating")),
      #("message", json.string("User has already rated this drink")),
    ])
    |> json.to_string,
  )
}

/// Extract user from request (placeholder - unit-2 handles auth)
fn extract_user(_request: Request) -> Option(UserSummary) {
  // Placeholder: would extract from auth token/session
  Some(shared.UserSummary(
    id: "user_123",
    username: "boba_lover",
  ))
}

/// Extract drink_id from path /api/drinks/:drink_id/ratings
fn extract_drink_id(path: String) -> Option(String) {
  case string.split(path, "/") {
    ["", "api", "drinks", drink_id, "ratings"] -> Some(drink_id)
    _ -> None
  }
}

/// Check if drink exists (placeholder - unit-9 implements drinks)
fn drink_exists(drink_id: String) -> Bool {
  drink_id != "" && !string.starts_with(drink_id, " ")
}

/// POST /api/drinks/:drink_id/ratings
pub fn create_rating(
  request: Request,
  store: RatingStore,
) -> Response {
  // Extract drink_id from path
  let drink_id_result = case extract_drink_id(request.path) {
    None -> Error("invalid path")
    Some(id) ->
      case drink_exists(id) {
        False -> Error("drink not found")
        True -> Ok(id)
      }
  }

  case drink_id_result {
    Error("drink not found") -> not_found_response("Drink")
    Error(_) ->
      validation_error_response("path", "invalid drink_id in path")
    Ok(drink_id) -> {
      // Extract user (placeholder until unit-2)
      case extract_user(request) {
        None ->
          json_response(
            401,
            json.object([#("error", json.string("Unauthorized"))])
            |> json.to_string,
          )
        Some(user) -> {
          // Parse request body
          case parse_create_input(request.body) {
            Error(#(field, message)) -> validation_error_response(field, message)
            Ok(input) -> {
              // Create rating record
              let rating = create_rating_record(drink_id, user.id, input)

              // Store rating
              case rating_store.create_rating(store, rating) {
                Error(shared.DuplicateRating) -> duplicate_rating_response()
                Error(_) ->
                  json_response(
                    500,
                    json.object([#("error", json.string("Internal error"))])
                    |> json.to_string,
                  )
                Ok(created_rating) -> {
                  // Return 201 with rating + user
                  json_response(
                    201,
                    rating_to_json(created_rating, user) |> json.to_string,
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

/// Handler for unsupported methods on rating endpoints
pub fn method_not_allowed() -> Response {
  json_response(
    405,
    json.object([#("error", json.string("Method not allowed"))])
    |> json.to_string,
  )
}
