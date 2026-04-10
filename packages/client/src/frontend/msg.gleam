/// Application messages

import shared.{type AppError}
import frontend/model.{type Store, type Drink, type Rating}

/// Application messages
pub type Msg {
  // Navigation
  NavigateToHome
  NavigateToStoreDetail(store_id: String)

  // Store detail page messages
  StoreDetailMsg(StoreDetailMsg)
}

/// Messages specific to the store detail page
pub type StoreDetailMsg {
  // API responses
  ReceivedStore(Result(Store, AppError))
  ReceivedDrinks(Result(List(Drink), AppError))
  ReceivedRatings(Result(List(Rating), AppError))

  // User actions
  ClickedAddDrink
  ClickedBack
}
