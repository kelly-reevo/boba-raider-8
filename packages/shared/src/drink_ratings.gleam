import gleam/json
import gleam/option.{type Option, None, Some}

/// Rating score from 1-5
pub type RatingScore {
  RatingScore(Int)
}

/// Create a rating score with validation
pub fn rating_score(value: Int) -> Result(RatingScore, String) {
  case value >= 1 && value <= 5 {
    True -> Ok(RatingScore(value))
    False -> Error("Rating must be between 1 and 5")
  }
}

/// Get integer value from rating
pub fn score_value(score: RatingScore) -> Int {
  let RatingScore(v) = score
  v
}

/// Drink rating record - shared between client and server
pub type DrinkRating {
  DrinkRating(
    id: String,
    drink_id: String,
    user_id: String,
    overall_score: RatingScore,
    sweetness: RatingScore,
    boba_texture: RatingScore,
    tea_strength: RatingScore,
    review_text: Option(String),
    created_at: String,
    updated_at: String,
  )
}

/// Create a DrinkRating from validated fields
pub fn new(
  id: String,
  drink_id: String,
  user_id: String,
  overall_score: Int,
  sweetness: Int,
  boba_texture: Int,
  tea_strength: Int,
  review_text: Option(String),
  created_at: String,
  updated_at: String,
) -> Result(DrinkRating, String) {
  case rating_score(overall_score) {
    Ok(overall) ->
      case rating_score(sweetness) {
        Ok(sweetness_score) ->
          case rating_score(boba_texture) {
            Ok(boba) ->
              case rating_score(tea_strength) {
                Ok(tea) ->
                  Ok(DrinkRating(
                    id: id,
                    drink_id: drink_id,
                    user_id: user_id,
                    overall_score: overall,
                    sweetness: sweetness_score,
                    boba_texture: boba,
                    tea_strength: tea,
                    review_text: review_text,
                    created_at: created_at,
                    updated_at: updated_at,
                  ))
                Error(e) -> Error(e)
              }
            Error(e) -> Error(e)
          }
        Error(e) -> Error(e)
      }
    Error(e) -> Error(e)
  }
}

/// Encode DrinkRating to JSON
pub fn to_json(rating: DrinkRating) -> json.Json {
  json.object([
    #("id", json.string(rating.id)),
    #("drink_id", json.string(rating.drink_id)),
    #("user_id", json.string(rating.user_id)),
    #("overall_score", json.int(score_value(rating.overall_score))),
    #("sweetness", json.int(score_value(rating.sweetness))),
    #("boba_texture", json.int(score_value(rating.boba_texture))),
    #("tea_strength", json.int(score_value(rating.tea_strength))),
    #("review_text", case rating.review_text {
      Some(text) -> json.string(text)
      None -> json.null()
    }),
    #("created_at", json.string(rating.created_at)),
    #("updated_at", json.string(rating.updated_at)),
  ])
}
