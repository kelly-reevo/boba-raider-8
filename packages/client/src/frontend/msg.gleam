import gleam/option.{type Option}
import shared.{type Drink, type Rating}

/// Application messages

pub type Msg {
  // Counter messages (legacy)
  Increment
  Decrement
  Reset

  // Drink detail messages
  LoadDrinkDetail(drink_id: String)
  DrinkDetailLoaded(Drink, List(Rating))
  UserRatingLoaded(Option(Rating))
  DrinkDetailError(String)
}
