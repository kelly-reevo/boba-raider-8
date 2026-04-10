import gleam/json
import gleam/option.{type Option, None, Some}
import web/server.{type Request, type Response, json_response}

/// Repository function to get store by ID (from unit-4 dependency)
@external(erlang, "store_repo", "get_store_by_id")
fn get_store_by_id(id: String) -> Option(Store)

type Store {
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

type StoreWithStats {
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

/// Repository function to get average rating for a store (from unit-15 dependency)
@external(erlang, "rating_repo", "get_average_rating")
fn get_average_rating(store_id: String) -> Option(Float)

/// Repository function to count drinks for a store (from unit-4 dependency)
@external(erlang, "store_repo", "count_drinks")
fn count_drinks(store_id: String) -> Int

/// Convert StoreWithStats to JSON
fn store_with_stats_to_json(store: StoreWithStats) -> json.Json {
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

fn option_to_json(value: Option(a), encoder: fn(a) -> json.Json) -> json.Json {
  case value {
    Some(v) -> encoder(v)
    None -> json.null()
  }
}

/// Handle GET /api/stores/:id
pub fn get_store(_request: Request, store_id: String) -> Response {
  case get_store_by_id(store_id) {
    Some(store) -> {
      // Aggregate data from dependencies
      let average_rating = get_average_rating(store_id)
      let drink_count = count_drinks(store_id)

      let store_with_stats = StoreWithStats(
        id: store.id,
        name: store.name,
        address: store.address,
        lat: store.lat,
        lng: store.lng,
        phone: store.phone,
        hours: store.hours,
        description: store.description,
        image_url: store.image_url,
        created_by: store.created_by,
        created_at: store.created_at,
        average_rating: average_rating,
        drink_count: drink_count,
      )

      let body =
        store_with_stats_to_json(store_with_stats)
        |> json.to_string

      json_response(200, body)
    }
    None -> {
      let body =
        json.object([#("error", json.string("Store not found"))])
        |> json.to_string
      json_response(404, body)
    }
  }
}
