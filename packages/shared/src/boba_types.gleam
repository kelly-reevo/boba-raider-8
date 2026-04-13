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
