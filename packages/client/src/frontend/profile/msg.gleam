import shared.{
  type DrinkRating, type ProfileTab, type StoreRating, type UserProfile,
}

/// Profile page messages
pub type Msg {
  // Profile loading
  LoadProfile
  ProfileLoaded(UserProfile)
  ProfileLoadFailed(String)

  // Tab switching
  SwitchTab(ProfileTab)

  // Store ratings
  LoadStoreRatings(page: Int)
  StoreRatingsLoaded(items: List(StoreRating), total: Int)
  StoreRatingsLoadFailed(String)

  // Drink ratings
  LoadDrinkRatings(page: Int)
  DrinkRatingsLoaded(items: List(DrinkRating), total: Int)
  DrinkRatingsLoadFailed(String)

  // Pagination
  ChangePage(Int)
}
