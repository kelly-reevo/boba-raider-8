/// Shared domain types for boba-raider-8

/// Store entity representing a boba shop
pub type Store {
  Store(
    id: Int,
    name: String,
    address: String,
    created_at: String,
  )
}

/// Drink entity representing a boba drink
pub type Drink {
  Drink(
    id: Int,
    store_id: Int,
    name: String,
    description: String,
    base_tea_type: String,
    price: Float,
    created_at: String,
  )
}

/// Rating entity representing a drink review
pub type Rating {
  Rating(
    id: Int,
    drink_id: Int,
    overall_rating: Int,
    sweetness: Int,
    boba_texture: Int,
    tea_strength: Int,
    created_at: String,
  )
}
