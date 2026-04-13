/// Application messages

import frontend/model.{type DrinkCard, type StoreInfo}

pub type Msg {
  // Navigation
  NavigateToStore(String)

  // Store API responses
  StoreLoaded(StoreInfo)
  StoreLoadFailed(Int)

  // Drinks API responses
  DrinksLoaded(List(DrinkCard))
  DrinksLoadFailed(String)

  // User actions
  ClickAddDrink

  // Deprecated - from original counter app
  Increment
  Decrement
  Reset
}
