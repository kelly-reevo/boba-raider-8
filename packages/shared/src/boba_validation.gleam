/// Validation types and input structures for boba-raider-8

import gleam/option.{type Option}

/// Input for creating a new store
pub type StoreInput {
  StoreInput(
    name: String,
    address: Option(String),
    phone: Option(String),
  )
}

/// Input for creating a new drink
pub type DrinkInput {
  DrinkInput(
    name: String,
    store_id: Int,
  )
}

/// Input for creating a new rating
pub type RatingInput {
  RatingInput(
    drink_id: Int,
    rating: Int,
    sweetness: Int,
    boba_texture: Int,
    tea_strength: Int,
    reviewer_name: Option(String),
    review_text: Option(String),
  )
}
