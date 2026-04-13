/// Drink Detail Effects - HTTP API calls for drink detail page

import frontend/drink_detail_model.{
  type DrinkDetail, DrinkDetail,
  type RatingAggregates, RatingAggregates,
  type Review, Review
}
import frontend/drink_detail_msg.{type DrinkDetailMsg}
import gleam/dynamic/decode
import gleam/json
import lustre/effect.{type Effect}

/// Base API URL - uses same origin in production
const api_base = "/api"

/// Fetch drink details from GET /api/drinks/:id
pub fn fetch_drink(drink_id: String) -> Effect(DrinkDetailMsg) {
  let url = api_base <> "/drinks/" <> drink_id

  let decoder = {
    use id <- decode.field("id", decode.string)
    use store_id <- decode.field("store_id", decode.string)
    use name <- decode.field("name", decode.string)
    use description <- decode.field("description", decode.optional(decode.string))
    use base_tea_type <- decode.field("base_tea_type", decode.optional(decode.string))
    use price <- decode.field("price", decode.optional(decode.float))

    decode.success(DrinkDetail(
      id: id,
      store_id: store_id,
      name: name,
      description: description,
      base_tea_type: base_tea_type,
      price: price,
    ))
  }

  effect.from(fn(dispatch) {
    case fetch_json(url) {
      Error(_) -> dispatch(drink_detail_msg.DrinkLoadFailed("Network error"))
      Ok(#(status, body)) -> {
        case status {
          404 -> dispatch(drink_detail_msg.DrinkLoadFailed("Drink not found"))
          _ -> {
            case json.parse(body, decoder) {
              Ok(drink) -> dispatch(drink_detail_msg.DrinkLoaded(drink))
              Error(_) -> dispatch(drink_detail_msg.DrinkLoadFailed("Invalid response"))
            }
          }
        }
      }
    }
  })
}

/// Fetch aggregate ratings from GET /api/drinks/:id/aggregates
pub fn fetch_aggregates(drink_id: String) -> Effect(DrinkDetailMsg) {
  let url = api_base <> "/drinks/" <> drink_id <> "/aggregates"

  let decoder = {
    use drink_id_field <- decode.field("drink_id", decode.string)
    use overall <- decode.field("overall_rating", decode.optional(decode.float))
    use sweetness <- decode.field("sweetness", decode.optional(decode.float))
    use boba_texture <- decode.field("boba_texture", decode.optional(decode.float))
    use tea_strength <- decode.field("tea_strength", decode.optional(decode.float))
    use count <- decode.field("count", decode.int)

    decode.success(RatingAggregates(
      drink_id: drink_id_field,
      overall_rating: overall,
      sweetness: sweetness,
      boba_texture: boba_texture,
      tea_strength: tea_strength,
      count: count,
    ))
  }

  effect.from(fn(dispatch) {
    case fetch_json(url) {
      Error(_) -> dispatch(drink_detail_msg.AggregatesLoadFailed("Network error"))
      Ok(#(status, body)) -> {
        case status {
          404 -> dispatch(drink_detail_msg.AggregatesLoadFailed("Drink not found"))
          _ -> {
            case json.parse(body, decoder) {
              Ok(aggregates) -> dispatch(drink_detail_msg.AggregatesLoaded(aggregates))
              Error(_) -> dispatch(drink_detail_msg.AggregatesLoadFailed("Invalid response"))
            }
          }
        }
      }
    }
  })
}

/// Fetch individual reviews from GET /api/drinks/:id/ratings
pub fn fetch_reviews(drink_id: String) -> Effect(DrinkDetailMsg) {
  let url = api_base <> "/drinks/" <> drink_id <> "/ratings"

  let review_decoder = {
    use id <- decode.field("id", decode.string)
    use drink_id_field <- decode.field("drink_id", decode.string)
    use reviewer_name <- decode.field("reviewer_name", decode.string)
    use overall_rating <- decode.field("overall_rating", decode.int)
    use sweetness <- decode.field("sweetness", decode.int)
    use boba_texture <- decode.field("boba_texture", decode.int)
    use tea_strength <- decode.field("tea_strength", decode.int)
    use review_text <- decode.field("review_text", decode.optional(decode.string))
    use created_at <- decode.field("created_at", decode.string)

    decode.success(Review(
      id: id,
      drink_id: drink_id_field,
      reviewer_name: reviewer_name,
      overall_rating: overall_rating,
      sweetness: sweetness,
      boba_texture: boba_texture,
      tea_strength: tea_strength,
      review_text: review_text,
      created_at: created_at,
    ))
  }

  let decoder = {
    use ratings <- decode.field("ratings", decode.list(review_decoder))
    use _total <- decode.field("total", decode.int)
    use _limit <- decode.field("limit", decode.int)
    use _offset <- decode.field("offset", decode.int)

    decode.success(ratings)
  }

  effect.from(fn(dispatch) {
    case fetch_json(url) {
      Error(_) -> dispatch(drink_detail_msg.ReviewsLoadFailed("Network error"))
      Ok(#(status, body)) -> {
        case status {
          404 -> dispatch(drink_detail_msg.ReviewsLoadFailed("Drink not found"))
          _ -> {
            case json.parse(body, decoder) {
              Ok(reviews) -> dispatch(drink_detail_msg.ReviewsLoaded(reviews))
              Error(_) -> dispatch(drink_detail_msg.ReviewsLoadFailed("Invalid response"))
            }
          }
        }
      }
    }
  })
}

/// Load all drink detail data in parallel
pub fn load_drink_detail(drink_id: String) -> Effect(DrinkDetailMsg) {
  effect.batch([
    fetch_drink(drink_id),
    fetch_aggregates(drink_id),
    fetch_reviews(drink_id),
  ])
}

// FFI for fetch API - JavaScript target
@external(javascript, "./drink_detail_effects_ffi.mjs", "fetch_json")
fn fetch_json(url: String) -> Result(#(Int, String), String)
