/// Application state

import shared.{type Store, type StoreFilters, type SortOption}

/// Remote data pattern for async data loading
pub type RemoteData(data, error) {
  NotAsked
  Loading
  Success(data)
  Failure(error)
}

/// Store list page state
pub type StoreListState {
  StoreListState(
    stores: RemoteData(List(Store), String),
    filters: StoreFilters,
    has_more: Bool,
  )
}

/// Main application model
pub type Model {
  Model(
    count: Int,
    error: String,
    store_list: StoreListState,
  )
}

/// Default filters for store list
fn default_store_list_state() -> StoreListState {
  StoreListState(
    stores: NotAsked,
    filters: shared.default_filters(),
    has_more: False,
  )
}

/// Initial model state
pub fn default() -> Model {
  Model(
    count: 0,
    error: "",
    store_list: default_store_list_state(),
  )
}

/// Initialize model with store list loading
pub fn with_store_list_loading() -> Model {
  Model(
    count: 0,
    error: "",
    store_list: StoreListState(
      stores: Loading,
      filters: shared.default_filters(),
      has_more: False,
    ),
  )
}
