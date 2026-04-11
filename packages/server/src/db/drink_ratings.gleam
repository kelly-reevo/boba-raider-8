// Unit 21: Drink Ratings Database Schema
// Pure type definitions and JSON serialization for drink ratings
// Database operations are handled via FFI in db/ffi.erl

import gleam/float
import gleam/int
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import gleam/string

// ============================================================================
// TYPES
// ============================================================================

/// Rating scale for dimensional attributes (1-5)
pub type RatingScale {
  Rating1
  Rating2
  Rating3
  Rating4
  Rating5
}

/// Drink rating record - represents a single user rating for a drink
/// Maps to drink_ratings table schema
pub type DrinkRating {
  DrinkRating(
    id: String,
    drink_id: String,
    user_id: String,
    sweetness: Option(RatingScale),
    boba_texture: Option(RatingScale),
    tea_strength: Option(RatingScale),
    overall_rating: RatingScale,
    review: Option(String),
    created_at: String,
    updated_at: String,
  )
}

/// Input for creating a new drink rating
pub type CreateDrinkRatingInput {
  CreateDrinkRatingInput(
    drink_id: String,
    user_id: String,
    sweetness: Option(RatingScale),
    boba_texture: Option(RatingScale),
    tea_strength: Option(RatingScale),
    overall_rating: RatingScale,
    review: Option(String),
  )
}

/// Input for updating an existing drink rating
/// Option<Option<T>> pattern: None = don't change, Some(None) = set null, Some(Some(v)) = set value
pub type UpdateDrinkRatingInput {
  UpdateDrinkRatingInput(
    id: String,
    sweetness: Option(Option(RatingScale)),
    boba_texture: Option(Option(RatingScale)),
    tea_strength: Option(Option(RatingScale)),
    overall_rating: Option(RatingScale),
    review: Option(Option(String)),
  )
}

/// Aggregate rating statistics for a drink
pub type DrinkRatingAggregate {
  DrinkRatingAggregate(
    drink_id: String,
    total_ratings: Int,
    average_overall: Float,
    average_sweetness: Option(Float),
    average_boba_texture: Option(Float),
    average_tea_strength: Option(Float),
  )
}

// ============================================================================
// RATING SCALE CONVERSIONS
// ============================================================================

/// Convert rating scale to integer
pub fn rating_to_int(rating: RatingScale) -> Int {
  case rating {
    Rating1 -> 1
    Rating2 -> 2
    Rating3 -> 3
    Rating4 -> 4
    Rating5 -> 5
  }
}

/// Parse integer to rating scale (fails outside 1-5 range)
pub fn int_to_rating(value: Int) -> Result(RatingScale, String) {
  case value {
    1 -> Ok(Rating1)
    2 -> Ok(Rating2)
    3 -> Ok(Rating3)
    4 -> Ok(Rating4)
    5 -> Ok(Rating5)
    _ -> Error("Rating must be between 1 and 5, got: " <> int.to_string(value))
  }
}

/// Parse integer to optional rating scale (None for invalid values)
pub fn int_to_rating_optional(value: Int) -> Option(RatingScale) {
  case int_to_rating(value) {
    Ok(r) -> Some(r)
    Error(_) -> None
  }
}

/// Validate that a rating value is within acceptable range (1-5)
pub fn is_valid_rating(value: Int) -> Bool {
  value >= 1 && value <= 5
}

// ============================================================================
// JSON SERIALIZATION
// ============================================================================

/// Serialize RatingScale to JSON
pub fn rating_scale_to_json(rating: RatingScale) -> Json {
  json.int(rating_to_int(rating))
}

/// Serialize optional RatingScale to JSON
fn optional_rating_scale_to_json(rating: Option(RatingScale)) -> Json {
  case rating {
    Some(r) -> rating_scale_to_json(r)
    None -> json.null()
  }
}

/// Serialize optional string to JSON
fn optional_string_to_json(value: Option(String)) -> Json {
  case value {
    Some(s) -> json.string(s)
    None -> json.null()
  }
}

/// Serialize DrinkRating to JSON
pub fn drink_rating_to_json(rating: DrinkRating) -> Json {
  json.object([
    #("id", json.string(rating.id)),
    #("drink_id", json.string(rating.drink_id)),
    #("user_id", json.string(rating.user_id)),
    #("sweetness", optional_rating_scale_to_json(rating.sweetness)),
    #("boba_texture", optional_rating_scale_to_json(rating.boba_texture)),
    #("tea_strength", optional_rating_scale_to_json(rating.tea_strength)),
    #("overall_rating", rating_scale_to_json(rating.overall_rating)),
    #("review", optional_string_to_json(rating.review)),
    #("created_at", json.string(rating.created_at)),
    #("updated_at", json.string(rating.updated_at)),
  ])
}

/// Serialize DrinkRating list to JSON array
pub fn drink_rating_list_to_json(ratings: List(DrinkRating)) -> Json {
  json.array(ratings, drink_rating_to_json)
}

/// Serialize CreateDrinkRatingInput to JSON
pub fn create_input_to_json(input: CreateDrinkRatingInput) -> Json {
  json.object([
    #("drink_id", json.string(input.drink_id)),
    #("user_id", json.string(input.user_id)),
    #("sweetness", optional_rating_scale_to_json(input.sweetness)),
    #("boba_texture", optional_rating_scale_to_json(input.boba_texture)),
    #("tea_strength", optional_rating_scale_to_json(input.tea_strength)),
    #("overall_rating", rating_scale_to_json(input.overall_rating)),
    #("review", optional_string_to_json(input.review)),
  ])
}

/// Serialize UpdateDrinkRatingInput to JSON
pub fn update_input_to_json(input: UpdateDrinkRatingInput) -> Json {
  // Convert Option<Option<T>> to appropriate JSON representation
  let sweetness_json = case input.sweetness {
    None -> json.null()  // Field not provided - don't update
    Some(None) -> json.string("__null__")  // Explicitly set to null
    Some(Some(r)) -> rating_scale_to_json(r)
  }
  let boba_texture_json = case input.boba_texture {
    None -> json.null()
    Some(None) -> json.string("__null__")
    Some(Some(r)) -> rating_scale_to_json(r)
  }
  let tea_strength_json = case input.tea_strength {
    None -> json.null()
    Some(None) -> json.string("__null__")
    Some(Some(r)) -> rating_scale_to_json(r)
  }
  let overall_rating_json = case input.overall_rating {
    None -> json.null()
    Some(r) -> rating_scale_to_json(r)
  }
  let review_json = case input.review {
    None -> json.null()
    Some(None) -> json.string("__null__")
    Some(Some(s)) -> json.string(s)
  }

  json.object([
    #("id", json.string(input.id)),
    #("sweetness", sweetness_json),
    #("boba_texture", boba_texture_json),
    #("tea_strength", tea_strength_json),
    #("overall_rating", overall_rating_json),
    #("review", review_json),
  ])
}

/// Serialize DrinkRatingAggregate to JSON
pub fn drink_rating_aggregate_to_json(agg: DrinkRatingAggregate) -> Json {
  json.object([
    #("drink_id", json.string(agg.drink_id)),
    #("total_ratings", json.int(agg.total_ratings)),
    #("average_overall", json.float(agg.average_overall)),
    #("average_sweetness", optional_string_to_json(
      option.map(agg.average_sweetness, fn(f) { float_to_string(f) })
    )),
    #("average_boba_texture", optional_string_to_json(
      option.map(agg.average_boba_texture, fn(f) { float_to_string(f) })
    )),
    #("average_tea_strength", optional_string_to_json(
      option.map(agg.average_tea_strength, fn(f) { float_to_string(f) })
    )),
  ])
}

/// Helper to convert float to string
fn float_to_string(f: Float) -> String {
  // Simple float to string conversion
  case f == int.to_float(float.truncate(f)) {
    True -> int.to_string(float.truncate(f))
    False -> string.inspect(f)
  }
}

// ============================================================================
// DATABASE CONSTRAINT DOCUMENTATION
// ============================================================================

/// Schema constraints for the drink_ratings table:
///
/// Primary Key:
/// - id: UUID, auto-generated
///
/// Foreign Keys:
/// - drink_id: UUID NOT NULL -> drinks(id) ON DELETE CASCADE
/// - user_id: UUID NOT NULL -> users(id)
///
/// Rating Dimensions (1-5 scale, CHECK constraints):
/// - sweetness: SMALLINT, nullable
/// - boba_texture: SMALLINT, nullable
/// - tea_strength: SMALLINT, nullable
/// - overall_rating: SMALLINT NOT NULL
///
/// Content:
/// - review: TEXT, nullable
///
/// Timestamps:
/// - created_at: TIMESTAMP WITH TIME ZONE, DEFAULT NOW()
/// - updated_at: TIMESTAMP WITH TIME ZONE, DEFAULT NOW()
///   (auto-updated via trigger)
///
/// Unique Constraints:
/// - UNIQUE(drink_id, user_id) - one rating per user per drink
///
/// Indexes:
/// - idx_drink_ratings_drink_id (for drink lookup)
/// - idx_drink_ratings_user_id (for user lookup)
/// - idx_drink_ratings_drink_user (for unique constraint lookups)
/// - idx_drink_ratings_created_at (for recent ratings queries)
/// - idx_drink_ratings_drink_overall (for aggregation queries)
pub fn schema_constraints() -> String {
  "See module documentation for drink_ratings schema constraints"
}
