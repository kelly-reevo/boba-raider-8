/// API effects for the frontend
///
/// NOTE: This module defines the effect contracts for API calls.
/// For JavaScript target, the actual HTTP implementation would use
/// browser's fetch API via FFI in effects_ffi.mjs

import frontend/msg.{type Msg}
import lustre/effect.{type Effect}

// --- Store API Effects ---

/// Fetch store details by ID
/// API: GET /api/stores/:id
/// Response: Store JSON object
pub fn fetch_store(_store_id: String) -> Effect(Msg) {
  // Placeholder: actual implementation would use fetch via FFI
  effect.none()
}

/// Fetch drinks for a store
/// API: GET /api/stores/:id/drinks
/// Response: Array of Drink JSON objects
pub fn fetch_drinks(_store_id: String) -> Effect(Msg) {
  // Placeholder: actual implementation would use fetch via FFI
  effect.none()
}

/// Fetch ratings for a store
/// API: GET /api/stores/:id/ratings
/// Response: Array of Rating JSON objects
pub fn fetch_ratings(_store_id: String) -> Effect(Msg) {
  // Placeholder: actual implementation would use fetch via FFI
  effect.none()
}

/// Fetch all store detail data in parallel
pub fn fetch_store_detail_data(store_id: String) -> Effect(Msg) {
  effect.batch([
    fetch_store(store_id),
    fetch_drinks(store_id),
    fetch_ratings(store_id),
  ])
}
