/// Shared types and functions for boba-raider-8

import gleam/option.{type Option}

pub type AppError {
  NotFound(String)
  InvalidInput(String)
  InternalError(String)
  Forbidden(String)
}

/// Convert an error to a human-readable message
pub fn error_message(error: AppError) -> String {
  case error {
    NotFound(msg) -> "Not found: " <> msg
    InvalidInput(msg) -> "Invalid input: " <> msg
    InternalError(msg) -> "Internal error: " <> msg
    Forbidden(msg) -> "Forbidden: " <> msg
  }
}

/// Rating represents a user's rating for a drink
pub type Rating {
  Rating(
    id: String,
    user_id: String,
    drink_id: String,
    overall_score: Int,
    sweetness: Int,
    boba_texture: Int,
    tea_strength: Int,
    review_text: String,
    created_at: String,
    updated_at: String,
  )
}

/// Request body for updating an existing rating (all fields optional)
pub type UpdateRatingRequest {
  UpdateRatingRequest(
    overall_score: Option(Int),
    sweetness: Option(Int),
    boba_texture: Option(Int),
    tea_strength: Option(Int),
    review_text: Option(String),
  )
}

/// Score must be between 1 and 10
pub fn valid_score(score: Int) -> Bool {
  score >= 1 && score <= 10
}

/// Review text max length
pub fn valid_review(text: String) -> Bool {
  string.length(text) <= 2000
}

/// Validate update request - returns error message if invalid
pub fn validate_update_request(req: UpdateRatingRequest) -> Result(Nil, String) {
  case req.overall_score {
    option.Some(score) ->
      case valid_score(score) {
        True -> Ok(Nil)
        False -> Error("overall_score must be between 1 and 10")
      }
    option.None -> Ok(Nil)
  }
  |> fn(r) {
    case r {
      Error(_) -> r
      Ok(_) ->
        case req.sweetness {
          option.Some(score) ->
            case valid_score(score) {
              True -> Ok(Nil)
              False -> Error("sweetness must be between 1 and 10")
            }
          option.None -> Ok(Nil)
        }
    }
  }
  |> fn(r) {
    case r {
      Error(_) -> r
      Ok(_) ->
        case req.boba_texture {
          option.Some(score) ->
            case valid_score(score) {
              True -> Ok(Nil)
              False -> Error("boba_texture must be between 1 and 10")
            }
          option.None -> Ok(Nil)
        }
    }
  }
  |> fn(r) {
    case r {
      Error(_) -> r
      Ok(_) ->
        case req.tea_strength {
          option.Some(score) ->
            case valid_score(score) {
              True -> Ok(Nil)
              False -> Error("tea_strength must be between 1 and 10")
            }
          option.None -> Ok(Nil)
        }
    }
  }
  |> fn(r) {
    case r {
      Error(_) -> r
      Ok(_) ->
        case req.review_text {
          option.Some(text) ->
            case valid_review(text) {
              True -> Ok(Nil)
              False -> Error("review_text must be 2000 characters or less")
            }
          option.None -> Ok(Nil)
        }
    }
  }
}

/// JSON encoder for Rating
import gleam/json
import gleam/string

pub fn rating_to_json(rating: Rating) -> json.Json {
  json.object([
    #("id", json.string(rating.id)),
    #("user_id", json.string(rating.user_id)),
    #("drink_id", json.string(rating.drink_id)),
    #("overall_score", json.int(rating.overall_score)),
    #("sweetness", json.int(rating.sweetness)),
    #("boba_texture", json.int(rating.boba_texture)),
    #("tea_strength", json.int(rating.tea_strength)),
    #("review_text", json.string(rating.review_text)),
    #("created_at", json.string(rating.created_at)),
    #("updated_at", json.string(rating.updated_at)),
  ])
}
