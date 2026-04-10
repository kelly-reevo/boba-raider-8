/// Rating domain types

import domain/drink.{type DrinkId}
import domain/user.{type UserId}

pub type RatingId =
  String

pub type Rating {
  Rating(
    id: RatingId,
    drink_id: DrinkId,
    user_id: UserId,
    score: Int,
    comment: String,
  )
}
