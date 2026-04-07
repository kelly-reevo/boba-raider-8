/// Shared types and functions for boba-raider-8

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

// --- Domain Types ---

pub type DrinkId {
  DrinkId(String)
}

pub type StoreId {
  StoreId(String)
}

pub type RatingId {
  RatingId(String)
}

pub type Drink {
  Drink(id: DrinkId, name: String, store_id: StoreId)
}

pub type Store {
  Store(id: StoreId, name: String, location: String)
}

/// Individual rating with per-dimension scores (1.0–5.0)
pub type Rating {
  Rating(
    id: RatingId,
    drink_id: DrinkId,
    store_id: StoreId,
    sweetness: Float,
    flavor: Float,
    value: Float,
  )
}

/// Aggregated rating statistics for a drink or store
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
