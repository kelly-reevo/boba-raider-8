import gleam/json.{type Json}

pub type Store {
  Store(
    id: String,
    name: String,
    address: String,
    phone: String,
    owner_id: String,
  )
}

pub fn store_to_json(store: Store) -> Json {
  json.object([
    #("id", json.string(store.id)),
    #("name", json.string(store.name)),
    #("address", json.string(store.address)),
    #("phone", json.string(store.phone)),
    #("owner_id", json.string(store.owner_id)),
  ])
}

pub fn store_list_to_json(stores: List(Store)) -> Json {
  json.object([#("stores", json.array(stores, store_to_json))])
}
