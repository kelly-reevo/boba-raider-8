/// Drink Detail Model - State management for drink detail page

import gleam/option.{type Option}

/// Individual rating/review from a user
pub type Review {
  Review(
    id: String,
    drink_id: String,
    reviewer_name: String,
    overall_rating: Int,
    sweetness: Int,
    boba_texture: Int,
    tea_strength: Int,
    review_text: Option(String),
    created_at: String,
  )
}

/// Aggregate ratings for a drink (from GET /api/drinks/:id/aggregates)
pub type RatingAggregates {
  RatingAggregates(
    drink_id: String,
    overall_rating: Option(Float),
    sweetness: Option(Float),
    boba_texture: Option(Float),
    tea_strength: Option(Float),
    count: Int,
  )
}

/// Full drink details (from GET /api/drinks/:id)
pub type DrinkDetail {
  DrinkDetail(
    id: String,
    store_id: String,
    name: String,
    description: Option(String),
    base_tea_type: Option(String),
    price: Option(Float),
  )
}

/// Page state for drink detail view
pub type DrinkDetailState {
  // Initial loading state before any data arrives
  LoadingDrink
  // Drink loaded, fetching aggregates and reviews
  LoadingDetails(drink: DrinkDetail)
  // All data loaded successfully
  Populated(
    drink: DrinkDetail,
    aggregates: RatingAggregates,
    reviews: List(Review),
  )
  // No reviews yet (drink exists but has no ratings)
  EmptyReviews(
    drink: DrinkDetail,
    aggregates: RatingAggregates,
  )
  // Drink not found (404 from any endpoint)
  DrinkNotFound(drink_id: String)
  // Network or server error
  LoadError(message: String)
}

/// Model for the drink detail page
pub type DrinkDetailModel {
  DrinkDetailModel(
    drink_id: String,
    state: DrinkDetailState,
  )
}

/// Create initial model for a drink detail page
pub fn initial(drink_id: String) -> DrinkDetailModel {
  DrinkDetailModel(
    drink_id: drink_id,
    state: LoadingDrink,
  )
}

/// Check if aggregates indicate empty reviews (count = 0)
pub fn has_no_reviews(aggregates: RatingAggregates) -> Bool {
  aggregates.count == 0
}
