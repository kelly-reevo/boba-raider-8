import gleam/option.{type Option}
import shared.{type Drink, type Rating}

/// Page state for drink detail
pub type DrinkDetailState {
  DrinkDetailLoading
  DrinkDetailError(String)
  DrinkDetailEmpty
  DrinkDetailPopulated(
    drink: Drink,
    user_rating: Option(Rating),
    other_ratings: List(Rating),
  )
}

/// Application state
pub type Model {
  Model(
    count: Int,
    error: String,
    drink_detail: DrinkDetailState,
  )
}

pub fn default() -> Model {
  Model(count: 0, error: "", drink_detail: DrinkDetailLoading)
}
