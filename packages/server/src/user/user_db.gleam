/// User data access layer

import gleam/dict
import gleam/option.{type Option, None, Some}
import user/user.{type UserProfile, RatingCounts, UserProfile}

/// Mock database - stores user records
/// In production, this would be a real database connection
const mock_users = [
  #(
    "user_001",
    UserProfile(
      id: "user_001",
      email: "alice@example.com",
      username: "alice",
      created_at: "2024-01-15T08:30:00Z",
      rating_counts: RatingCounts(store_ratings: 5, drink_ratings: 12),
    ),
  ),
  #(
    "user_002",
    UserProfile(
      id: "user_002",
      email: "bob@example.com",
      username: "bob",
      created_at: "2024-02-20T14:22:00Z",
      rating_counts: RatingCounts(store_ratings: 3, drink_ratings: 8),
    ),
  ),
]

/// Get user profile by ID with current rating counts
/// Integrates with rating systems (unit-14: drink ratings, unit-17: store ratings)
pub fn get_user_profile(user_id: String) -> Option(UserProfile) {
  // Look up base user record
  let users = dict.from_list(mock_users)
  case dict.get(users, user_id) {
    Ok(base_profile) -> {
      // Aggregate current rating counts from rating subsystems
      let store_count = count_store_ratings(user_id)
      let drink_count = count_drink_ratings(user_id)

      Some(
        UserProfile(
          ..base_profile,
          rating_counts: RatingCounts(
            store_ratings: store_count,
            drink_ratings: drink_count,
          ),
        ),
      )
    }
    Error(_) -> None
  }
}

/// Count store ratings for a user (unit-17 dependency)
/// Returns number of store ratings created by this user
fn count_store_ratings(user_id: String) -> Int {
  // Integration point: calls store rating subsystem
  // For now, uses mock data - replace with actual store_rating.count_by_user(user_id)
  case user_id {
    "user_001" -> 5
    "user_002" -> 3
    _ -> 0
  }
}

/// Count drink ratings for a user (unit-14 dependency)
/// Returns number of drink ratings created by this user
fn count_drink_ratings(user_id: String) -> Int {
  // Integration point: calls drink rating subsystem
  // For now, uses mock data - replace with actual drink_rating.count_by_user(user_id)
  case user_id {
    "user_001" -> 12
    "user_002" -> 8
    _ -> 0
  }
}
