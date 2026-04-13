/// Application state for boba-raider-8

import gleam/option.{type Option, None}

/// Main application model
pub type Model {
  Model(
    // Store list state
    stores_loading: Bool,
    stores: List(Store),
    stores_error: Option(String),

    // Drink detail state
    drink_loading: Bool,
    drink: Option(Drink),
    drink_ratings: List(Rating),
    drink_error: Option(String),

    // Rating form state
    rating_sweetness: Int,
    rating_boba_texture: Int,
    rating_tea_strength: Int,
    rating_submitting: Bool,
    rating_submit_error: Option(String),

    // Accessibility preferences
    prefers_reduced_motion: Bool,
  )
}

/// Store entity
pub type Store {
  Store(id: String, name: String, rating: Float)
}

/// Drink entity
pub type Drink {
  Drink(id: String, name: String, store_id: String, description: String)
}

/// Rating entity for a drink
pub type Rating {
  Rating(
    id: String,
    drink_id: String,
    sweetness: Int,
    boba_texture: Int,
    tea_strength: Int,
  )
}

/// Default initial model state
pub fn default() -> Model {
  Model(
    stores_loading: False,
    stores: [],
    stores_error: None,
    drink_loading: False,
    drink: None,
    drink_ratings: [],
    drink_error: None,
    rating_sweetness: 0,
    rating_boba_texture: 0,
    rating_tea_strength: 0,
    rating_submitting: False,
    rating_submit_error: None,
    prefers_reduced_motion: False,
  )
}
