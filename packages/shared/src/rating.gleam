/// Shared types for store ratings

pub type Rating {
  Rating(
    id: String,
    store_id: String,
    user_id: String,
    score: Int,
  )
}

pub type RatingError {
  RatingNotFound
  RatingNotOwner
  InvalidScore
}
