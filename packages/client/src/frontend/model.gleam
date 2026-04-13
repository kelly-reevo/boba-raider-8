/// Application state

import gleam/option.{type Option, None, Some}

/// Drink card for display in store detail view
pub type DrinkCard {
  DrinkCard(
    id: String,
    name: String,
    base_tea_type: String,
    price: Float,
    overall_rating: Float,
  )
}

/// Store information for header display
pub type StoreInfo {
  StoreInfo(
    id: String,
    name: String,
    location: String,
  )
}

/// Page state for store detail view
pub type PageState {
  Loading
  Loaded
  Error(String)
  NotFound
}

/// Main application model
pub type Model {
  Model(
    // Current page state
    page_state: PageState,
    // Store information for header
    store: Option(StoreInfo),
    // List of drinks for the store
    drinks: List(DrinkCard),
    // Current store ID from route
    current_store_id: Option(String),
    // Error message if any
    error: String,
    // Legacy field - maintained for backward compatibility
    count: Int,
  )
}

pub fn default() -> Model {
  Model(
    page_state: Loading,
    store: None,
    drinks: [],
    current_store_id: None,
    error: "",
    count: 0,
  )
}

/// Create model for store detail page
pub fn init_store_detail(store_id: String) -> Model {
  Model(
    page_state: Loading,
    store: None,
    drinks: [],
    current_store_id: Some(store_id),
    error: "",
    count: 0,
  )
}
