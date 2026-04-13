/// Drink Detail Messages - Actions for the drink detail page

import frontend/drink_detail_model.{type DrinkDetail, type RatingAggregates, type Review}

/// Messages specific to the drink detail page
pub type DrinkDetailMsg {
  // Navigation - load a drink detail page
  LoadDrinkDetail(drink_id: String)

  // Data loaded successfully
  DrinkLoaded(DrinkDetail)
  AggregatesLoaded(RatingAggregates)
  ReviewsLoaded(List(Review))

  // Loading failed
  DrinkLoadFailed(String)
  AggregatesLoadFailed(String)
  ReviewsLoadFailed(String)

  // User actions
  AddRatingClicked(drink_id: String)
  BackToStoreClicked(store_id: String)

  // Retry failed load
  RetryLoad
}
