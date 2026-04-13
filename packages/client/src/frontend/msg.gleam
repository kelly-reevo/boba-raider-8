/// Application messages

import frontend/model.{type Drink, type Rating, type Store}

/// Application messages for MVU cycle
pub type Msg {
  // Store list messages
  LoadStoresRequest
  LoadStoresSuccess(stores: List(Store))
  LoadStoresError(error: String)

  // Drink detail messages
  LoadDrinkRequest(drink_id: String)
  LoadDrinkSuccess(drink: Drink, ratings: List(Rating))
  LoadDrinkError(error: String)

  // Rating form messages
  UpdateSweetness(value: Int)
  UpdateBobaTexture(value: Int)
  UpdateTeaStrength(value: Int)
  SubmitRatingRequest
  SubmitRatingSuccess
  SubmitRatingError(error: String)

  // Accessibility messages
  SetReducedMotion(prefers_reduced_motion: Bool)

  // Retry actions
  RetryLoadStores
  RetryLoadDrink
}
