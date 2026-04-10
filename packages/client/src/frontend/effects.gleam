/// API effects for the frontend

import frontend/msg.{type Msg}
import gleam/int
import gleam/option.{type Option}
import lustre/effect.{type Effect}

/// POST /api/stores/:id/ratings - Create or update a store rating
pub fn submit_store_rating(
  store_id: String,
  _rating_id: Option(String),
  overall_score: Int,
  _review_text: String,
) -> Effect(Msg) {
  use dispatch <- effect.from

  // Simulate API call - will be replaced with actual HTTP implementation
  // when gleam_fetch or similar package is available
  case overall_score > 0 && overall_score <= 5 {
    True -> {
      // Simulate success
      dispatch(msg.RatingCreated(store_id))
    }
    False -> {
      dispatch(msg.RatingApiError("Invalid rating score: " <> int.to_string(overall_score)))
    }
  }
}

/// DELETE /api/ratings/store/:id - Delete a store rating
pub fn delete_store_rating(store_id: String, _rating_id: String) -> Effect(Msg) {
  use dispatch <- effect.from

  // Simulate API call - will be replaced with actual HTTP implementation
  dispatch(msg.RatingDeleted(store_id))
}

/// Placeholder effect (for other data fetching)
pub fn fetch_data() -> Effect(Msg) {
  effect.none()
}
