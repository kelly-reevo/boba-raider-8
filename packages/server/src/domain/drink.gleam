/// Drink domain types

import domain/user.{type UserId}

pub type DrinkId =
  String

pub type StoreId =
  String

pub type Drink {
  Drink(
    id: DrinkId,
    store_id: StoreId,
    creator_id: UserId,
    name: String,
    description: String,
  )
}

pub fn is_creator(drink: Drink, user_id: UserId) -> Bool {
  drink.creator_id == user_id
}
