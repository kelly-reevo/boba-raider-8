/// Shared types and functions for boba-raider-8

import gleam/dynamic/decode
import gleam/json

pub type AppError {
  NotFound(String)
  InvalidInput(String)
  InternalError(String)
}

/// Convert an error to a human-readable message
pub fn error_message(error: AppError) -> String {
  case error {
    NotFound(msg) -> "Not found: " <> msg
    InvalidInput(msg) -> "Invalid input: " <> msg
    InternalError(msg) -> "Internal error: " <> msg
  }
}

// --- Rating types ---

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
