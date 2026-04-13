import gleam/dict.{type Dict}
import gleam/option.{type Option}

/// Store record representing a boba store for app layer
pub type Store {
  Store(
    id: String,
    name: String,
    address: Option(String),
    city: Option(String),
    phone: Option(String),
    created_at: String,
    updated_at: String,
  )
}

/// Store state is a simple Dict of store_id -> Store
pub type StoreState =
  Dict(String, Store)

/// Create empty store state
pub fn new_state() -> StoreState {
  dict.new()
}
