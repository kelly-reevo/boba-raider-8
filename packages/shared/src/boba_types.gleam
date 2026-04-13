/// Boba Types - Shared domain types for boba-raider-8
/// Used across frontend, backend, and validation layers

import gleam/option.{type Option, Some, None}
import gleam/json.{type Json}

/// Store record representing a boba store
pub type Store {
  Store(
    id: String,
    name: String,
    address: Option(String),
    city: Option(String),
    phone: Option(String),
    drink_count: Int,
    created_at: String,
  )
}

/// Drink record representing a boba drink
pub type Drink {
  Drink(
    id: String,
    store_id: Int,
    name: String,
  )
}

/// Encode a Store to JSON
pub fn store_to_json(store: Store) -> Json {
  json.object([
    #("id", json.string(store.id)),
    #("name", json.string(store.name)),
    #("address", case store.address {
      Some(a) -> json.string(a)
      None -> json.null()
    }),
    #("city", case store.city {
      Some(c) -> json.string(c)
      None -> json.null()
    }),
    #("phone", case store.phone {
      Some(p) -> json.string(p)
      None -> json.null()
    }),
    #("drink_count", json.int(store.drink_count)),
    #("created_at", json.string(store.created_at)),
  ])
}

/// Encode a list of stores to JSON
pub fn stores_to_json(stores: List(Store)) -> Json {
  json.array(stores, store_to_json)
}

/// Store list response for paginated API
pub type StoreListResponse {
  StoreListResponse(
    stores: List(Store),
    total: Int,
  )
}

/// Encode store list response to JSON
pub fn store_list_response_to_json(response: StoreListResponse) -> Json {
  json.object([
    #("stores", stores_to_json(response.stores)),
    #("total", json.int(response.total)),
  ])
}

/// Store list item for simplified API response
/// Matches the expected JSON format from boundary contract
pub type StoreListItem {
  StoreListItem(
    id: String,
    name: String,
    city: String,
    drink_count: Int,
  )
}

/// Encode a store list item to JSON
pub fn store_list_item_to_json(item: StoreListItem) -> Json {
  json.object([
    #("id", json.string(item.id)),
    #("name", json.string(item.name)),
    #("city", json.string(item.city)),
    #("drink_count", json.int(item.drink_count)),
  ])
}

/// Simplified store list response
pub type SimpleStoreListResponse {
  SimpleStoreListResponse(
    stores: List(StoreListItem),
    total: Int,
  )
}

/// Encode simplified store list response to JSON
pub fn simple_store_list_response_to_json(response: SimpleStoreListResponse) -> Json {
  json.object([
    #("stores", json.array(response.stores, store_list_item_to_json)),
    #("total", json.int(response.total)),
  ])
}
