import shared.{type DrinkRating, type LoadState, type ProfileTab, type StoreRating, type UserProfile, Loading, StoreRatingsTab}

/// Profile page state
pub type Model {
  Model(
    // User profile data
    profile: LoadState(UserProfile),
    // Active tab
    active_tab: ProfileTab,
    // Store ratings for current page
    store_ratings: LoadState(List(StoreRating)),
    // Drink ratings for current page
    drink_ratings: LoadState(List(DrinkRating)),
    // Pagination state
    current_page: Int,
    per_page: Int,
    store_ratings_total: Int,
    drink_ratings_total: Int,
  )
}

pub fn default() -> Model {
  Model(
    profile: Loading,
    active_tab: StoreRatingsTab,
    store_ratings: Loading,
    drink_ratings: Loading,
    current_page: 1,
    per_page: 10,
    store_ratings_total: 0,
    drink_ratings_total: 0,
  )
}
