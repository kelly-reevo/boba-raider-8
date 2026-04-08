import gleam/dynamic/decode
import gleam/json

pub type Rating {
  Rating(
    id: String,
    user_id: String,
    drink_id: String,
    sweetness_score: Int,
    boba_texture_score: Int,
    tea_strength_score: Int,
    overall_score: Int,
    review_text: String,
  )
}

pub fn encoder(rating: Rating) -> json.Json {
  json.object([
    #("id", json.string(rating.id)),
    #("user_id", json.string(rating.user_id)),
    #("drink_id", json.string(rating.drink_id)),
    #("sweetness_score", json.int(rating.sweetness_score)),
    #("boba_texture_score", json.int(rating.boba_texture_score)),
    #("tea_strength_score", json.int(rating.tea_strength_score)),
    #("overall_score", json.int(rating.overall_score)),
    #("review_text", json.string(rating.review_text)),
  ])
}

pub fn decoder() -> decode.Decoder(Rating) {
  use id <- decode.field("id", decode.string)
  use user_id <- decode.field("user_id", decode.string)
  use drink_id <- decode.field("drink_id", decode.string)
  use sweetness_score <- decode.field("sweetness_score", decode.int)
  use boba_texture_score <- decode.field("boba_texture_score", decode.int)
  use tea_strength_score <- decode.field("tea_strength_score", decode.int)
  use overall_score <- decode.field("overall_score", decode.int)
  use review_text <- decode.field("review_text", decode.string)
  decode.success(Rating(
    id:,
    user_id:,
    drink_id:,
    sweetness_score:,
    boba_texture_score:,
    tea_strength_score:,
    overall_score:,
    review_text:,
  ))
}
