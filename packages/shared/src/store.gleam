import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}

/// Store domain model
pub type Store {
  Store(
    id: String,
    name: String,
    address: String,
    lat: Float,
    lng: Float,
    phone: Option(String),
    hours: Option(String),
    description: Option(String),
    image_url: Option(String),
    created_by: String,
    created_at: String,
  )
}

/// Store with aggregated statistics
pub type StoreWithStats {
  StoreWithStats(
    id: String,
    name: String,
    address: String,
    lat: Float,
    lng: Float,
    phone: Option(String),
    hours: Option(String),
    description: Option(String),
    image_url: Option(String),
    created_by: String,
    created_at: String,
    average_rating: Option(Float),
    drink_count: Int,
  )
}

/// Convert StoreWithStats to JSON
pub fn store_with_stats_to_json(store: StoreWithStats) -> Json {
  json.object([
    #("id", json.string(store.id)),
    #("name", json.string(store.name)),
    #("address", json.string(store.address)),
    #("lat", json.float(store.lat)),
    #("lng", json.float(store.lng)),
    #("phone", option_to_json(store.phone, json.string)),
    #("hours", option_to_json(store.hours, json.string)),
    #("description", option_to_json(store.description, json.string)),
    #("image_url", option_to_json(store.image_url, json.string)),
    #("created_by", json.string(store.created_by)),
    #("created_at", json.string(store.created_at)),
    #("average_rating", option_to_json(store.average_rating, json.float)),
    #("drink_count", json.int(store.drink_count)),
  ])
}

fn option_to_json(value: Option(a), encoder: fn(a) -> Json) -> Json {
  case value {
    Some(v) -> encoder(v)
    None -> json.null()
  }
}
