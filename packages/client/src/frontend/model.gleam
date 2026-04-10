/// Application state

import shared.{type AppError}

/// Authentication state for the user
pub type AuthState {
  Authenticated(user_id: String, username: String)
  Anonymous
}

/// Data for a single store
pub type Store {
  Store(
    id: String,
    name: String,
    address: String,
    city: String,
    state: String,
    zip: String,
    phone: String,
    latitude: Float,
    longitude: Float,
    description: String,
    website: String,
  )
}

/// Data for a drink available at a store
pub type Drink {
  Drink(
    id: String,
    name: String,
    description: String,
    price: Float,
    currency: String,
    category: String,
    image_url: String,
  )
}

/// Rating/review for a store
pub type Rating {
  Rating(
    id: String,
    user_id: String,
    username: String,
    rating: Int,
    review: String,
    created_at: String,
  )
}

/// Loading state for async data
pub type LoadState(a) {
  Loading
  Error(AppError)
  Loaded(a)
}

/// Combined data for the store detail page
pub type StoreData {
  StoreData(
    store: Store,
    drinks: List(Drink),
    ratings: List(Rating),
  )
}

/// Page-specific model for store detail
pub type StoreDetailModel {
  StoreDetailModel(
    store_id: String,
    data: LoadState(StoreData),
    auth: AuthState,
  )
}

/// Global application model
pub type Model {
  Model(
    current_page: Page,
    auth: AuthState,
  )
}

/// Application pages
pub type Page {
  Home
  StoreDetail(String)
}

/// Default model state
pub fn default() -> Model {
  Model(
    current_page: Home,
    auth: Anonymous,
  )
}

/// Create a store detail model with loading state
pub fn init_store_detail(store_id: String, auth: AuthState) -> StoreDetailModel {
  StoreDetailModel(
    store_id: store_id,
    data: Loading,
    auth: auth,
  )
}
