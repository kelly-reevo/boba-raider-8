/// Shared types and functions for boba-raider-8

import gleam/dynamic/decode
import gleam/json

pub type AppError {
  NotFound(String)
  InvalidInput(String)
  InternalError(String)
  Unauthorized(String)
}

/// Convert an error to a human-readable message
pub fn error_message(error: AppError) -> String {
  case error {
    NotFound(msg) -> "Not found: " <> msg
    InvalidInput(msg) -> "Invalid input: " <> msg
    InternalError(msg) -> "Internal error: " <> msg
    Unauthorized(msg) -> "Unauthorized: " <> msg
  }
}

/// A rating for a boba drink with boba-specific scoring dimensions
pub type Rating {
  Rating(
    id: String,
    drink_id: String,
    user_id: String,
    sweetness: Int,
    texture: Int,
    flavor: Int,
    overall: Int,
    review: String,
  )
}

/// Aggregated ratings for a drink
pub type AggregatedRating {
  AggregatedRating(
    drink_id: String,
    avg_sweetness: Float,
    avg_texture: Float,
    avg_flavor: Float,
    avg_overall: Float,
    count: Int,
  )
}

/// Aggregated rating statistics for a drink or store (per-dimension scores)
pub type RatingAggregation {
  RatingAggregation(
    count: Int,
    avg_sweetness: Float,
    avg_flavor: Float,
    avg_value: Float,
    overall: Float,
  )
}

/// Empty aggregation for entities with no ratings
pub const empty_aggregation = RatingAggregation(
  count: 0,
  avg_sweetness: 0.0,
  avg_flavor: 0.0,
  avg_value: 0.0,
  overall: 0.0,
)

/// Response from login/register endpoints
pub type AuthResponse {
  AuthResponse(token: String, user_id: String, username: String, email: String)
}

/// A boba store with aggregated rating data (frontend view)
pub type Store {
  Store(
    id: String,
    name: String,
    address: String,
    description: String,
    average_rating: Float,
    rating_count: Int,
  )
}

/// A drink with aggregated rating data (frontend view)
pub type FrontendDrink {
  FrontendDrink(
    id: String,
    store_id: String,
    name: String,
    description: String,
    price_cents: Int,
    average_rating: Float,
    rating_count: Int,
  )
}

/// Rating values use 1-5 integer scale, 0 means unset
pub type RatingSubmission {
  RatingSubmission(
    sweetness: Int,
    boba_texture: Int,
    tea_strength: Int,
    overall: Int,
  )
}

pub fn empty_rating() -> RatingSubmission {
  RatingSubmission(sweetness: 0, boba_texture: 0, tea_strength: 0, overall: 0)
}

pub fn is_rating_complete(rating: RatingSubmission) -> Bool {
  rating.sweetness > 0
  && rating.boba_texture > 0
  && rating.tea_strength > 0
  && rating.overall > 0
}

// --- Rating display types ---

pub type Review {
  Review(
    id: String,
    author: String,
    rating: Int,
    text: String,
    created_at: String,
  )
}

/// Distribution of ratings from 1 to 5 stars
pub type RatingDistribution {
  RatingDistribution(
    one: Int,
    two: Int,
    three: Int,
    four: Int,
    five: Int,
  )
}

pub type RatingsSummary {
  RatingsSummary(
    average: Float,
    total_count: Int,
    distribution: RatingDistribution,
    reviews: List(Review),
  )
}

// --- JSON decoders ---

pub fn store_decoder() -> decode.Decoder(Store) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use address <- decode.field("address", decode.string)
  use description <- decode.field("description", decode.string)
  use average_rating <- decode.field("average_rating", decode.float)
  use rating_count <- decode.field("rating_count", decode.int)
  decode.success(Store(
    id: id,
    name: name,
    address: address,
    description: description,
    average_rating: average_rating,
    rating_count: rating_count,
  ))
}

pub fn stores_response_decoder() -> decode.Decoder(List(Store)) {
  use stores <- decode.field("stores", decode.list(store_decoder()))
  decode.success(stores)
}

pub fn drink_decoder() -> decode.Decoder(FrontendDrink) {
  use id <- decode.field("id", decode.string)
  use store_id <- decode.field("store_id", decode.string)
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.string)
  use price_cents <- decode.field("price_cents", decode.int)
  use average_rating <- decode.field("average_rating", decode.float)
  use rating_count <- decode.field("rating_count", decode.int)
  decode.success(FrontendDrink(
    id: id,
    store_id: store_id,
    name: name,
    description: description,
    price_cents: price_cents,
    average_rating: average_rating,
    rating_count: rating_count,
  ))
}

pub fn drinks_decoder() -> decode.Decoder(List(FrontendDrink)) {
  decode.list(drink_decoder())
}

pub fn review_decoder() -> decode.Decoder(Review) {
  use id <- decode.field("id", decode.string)
  use author <- decode.field("author", decode.string)
  use rating <- decode.field("rating", decode.int)
  use text <- decode.field("text", decode.string)
  use created_at <- decode.field("created_at", decode.string)
  decode.success(Review(
    id: id,
    author: author,
    rating: rating,
    text: text,
    created_at: created_at,
  ))
}

pub fn distribution_decoder() -> decode.Decoder(RatingDistribution) {
  use one <- decode.field("one", decode.int)
  use two <- decode.field("two", decode.int)
  use three <- decode.field("three", decode.int)
  use four <- decode.field("four", decode.int)
  use five <- decode.field("five", decode.int)
  decode.success(RatingDistribution(
    one: one,
    two: two,
    three: three,
    four: four,
    five: five,
  ))
}

pub fn ratings_summary_decoder() -> decode.Decoder(RatingsSummary) {
  use average <- decode.field("average", decode.float)
  use total_count <- decode.field("total_count", decode.int)
  use distribution <- decode.field("distribution", distribution_decoder())
  use reviews <- decode.field("reviews", decode.list(review_decoder()))
  decode.success(RatingsSummary(
    average: average,
    total_count: total_count,
    distribution: distribution,
    reviews: reviews,
  ))
}

pub fn decode_ratings_summary(
  json_string: String,
) -> Result(RatingsSummary, json.DecodeError) {
  json.parse(json_string, ratings_summary_decoder())
}
