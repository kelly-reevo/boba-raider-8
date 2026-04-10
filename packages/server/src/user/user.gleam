/// User domain types and functions

import gleam/dict.{type Dict}
import gleam/json.{type Json}
import gleam/string

/// User profile with rating statistics
pub type UserProfile {
  UserProfile(
    id: String,
    email: String,
    username: String,
    created_at: String,
    rating_counts: RatingCounts,
  )
}

/// Rating count statistics
pub type RatingCounts {
  RatingCounts(
    store_ratings: Int,
    drink_ratings: Int,
  )
}

/// Convert UserProfile to JSON
pub fn profile_to_json(profile: UserProfile) -> Json {
  json.object([
    #("id", json.string(profile.id)),
    #("email", json.string(profile.email)),
    #("username", json.string(profile.username)),
    #("created_at", json.string(profile.created_at)),
    #("rating_counts", rating_counts_to_json(profile.rating_counts)),
  ])
}

/// Convert RatingCounts to JSON
fn rating_counts_to_json(counts: RatingCounts) -> Json {
  json.object([
    #("store_ratings", json.int(counts.store_ratings)),
    #("drink_ratings", json.int(counts.drink_ratings)),
  ])
}

/// Parse user ID from auth header (Bearer token)
/// Returns Error if missing or malformed
pub fn extract_user_id(headers: Dict(String, String)) -> Result(String, Nil) {
  case dict.get(headers, "authorization") {
    Ok(header) -> extract_bearer_token(header)
    Error(_) -> Error(Nil)
  }
}

/// Extract bearer token from Authorization header value
fn extract_bearer_token(header: String) -> Result(String, Nil) {
  let parts = string.split(header, " ")
  case parts {
    ["Bearer", token] -> Ok(string.trim(token))
    _ -> Error(Nil)
  }
}
