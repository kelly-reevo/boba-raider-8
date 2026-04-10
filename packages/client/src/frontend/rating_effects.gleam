/// Rating API effects (simplified - no external HTTP dependency)

import frontend/rating_model.{type RatingForm}
import frontend/rating_msg.{type RatingMsg}
import lustre/effect.{type Effect}

/// Placeholder for rating submission effect
/// In production, this would make actual HTTP requests to:
/// - POST /api/drinks/:id/ratings for new ratings
/// - PATCH /api/ratings/drink/:id for updates
pub fn submit_rating(_form: RatingForm) -> Effect(RatingMsg) {
  // Simulated submission - replace with actual HTTP call
  effect.none()
}
