/// Store domain module - boba store listing with pagination, sorting, and filtering

import gleam/dict
import gleam/float
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string
import trig
import shared.{InvalidInput}

pub type StoreId {
  StoreId(String)
}

pub type Store {
  Store(
    id: StoreId,
    name: String,
    address: String,
    lat: Float,
    lng: Float,
    image_url: Option(String),
    average_rating: Option(Float),
  )
}

pub type SortBy {
  RatingDesc
  RatingAsc
  Name
  Distance
}

pub type PaginationMeta {
  PaginationMeta(
    total: Int,
    page: Int,
    limit: Int,
    total_pages: Int,
  )
}

pub type ListStoresResult {
  ListStoresResult(
    data: List(Store),
    meta: PaginationMeta,
  )
}

pub type ListStoresParams {
  ListStoresParams(
    lat: Option(Float),
    lng: Option(Float),
    radius: Option(Float),
    q: Option(String),
    sort: SortBy,
    page: Int,
    limit: Int,
  )
}

fn parse_float(s: String) -> Result(Float, Nil) {
  float.parse(s)
}

fn parse_int(s: String) -> Result(Int, Nil) {
  int.parse(s)
}

fn parse_sort(s: String) -> SortBy {
  case s {
    "rating_desc" -> RatingDesc
    "rating_asc" -> RatingAsc
    "name" -> Name
    "distance" -> Distance
    _ -> RatingDesc
  }
}

/// Parse query string parameters into ListStoresParams
/// The query string format is "key=value&key2=value2"
pub fn parse_params(query: String) -> Result(ListStoresParams, shared.AppError) {
  let params =
    query
    |> string.split("&")
    |> list.filter(fn(s) { s != "" })
    |> list.fold(dict.new(), fn(acc, pair) {
      case string.split(pair, "=") {
        [key, value] -> dict.insert(acc, key, value)
        _ -> acc
      }
    })

  let lat = dict.get(params, "lat") |> result.try(parse_float) |> option.from_result
  let lng = dict.get(params, "lng") |> result.try(parse_float) |> option.from_result
  let radius = dict.get(params, "radius") |> result.try(parse_float) |> option.from_result
  let q = dict.get(params, "q") |> option.from_result
  let sort = dict.get(params, "sort") |> result.unwrap("rating_desc") |> parse_sort
  let page = dict.get(params, "page") |> result.try(parse_int) |> result.unwrap(1)
  let limit = dict.get(params, "limit") |> result.try(parse_int) |> result.unwrap(20)

  // Validate pagination
  case page < 1, limit < 1 || limit > 100 {
    True, _ -> Error(InvalidInput("page must be >= 1"))
    _, True -> Error(InvalidInput("limit must be between 1 and 100"))
    _, _ -> Ok(ListStoresParams(lat, lng, radius, q, sort, page, limit))
  }
}

// Mock data - in production this would come from a database
fn mock_stores() -> List(Store) {
  [
    Store(
      id: StoreId("store-1"),
      name: "Boba Bliss",
      address: "123 Main St, San Francisco, CA",
      lat: 37.7749,
      lng: -122.4194,
      image_url: option.Some("https://example.com/boba-bliss.jpg"),
      average_rating: option.Some(4.5),
    ),
    Store(
      id: StoreId("store-2"),
      name: "Tea Time",
      address: "456 Market St, San Francisco, CA",
      lat: 37.7930,
      lng: -122.3959,
      image_url: option.None,
      average_rating: option.Some(4.2),
    ),
    Store(
      id: StoreId("store-3"),
      name: "Milk Tea Lab",
      address: "789 Valencia St, San Francisco, CA",
      lat: 37.7596,
      lng: -122.4218,
      image_url: option.Some("https://example.com/milk-tea-lab.jpg"),
      average_rating: option.Some(4.8),
    ),
    Store(
      id: StoreId("store-4"),
      name: "Bubble Bar",
      address: "321 Castro St, San Francisco, CA",
      lat: 37.7608,
      lng: -122.4350,
      image_url: option.None,
      average_rating: option.Some(3.9),
    ),
    Store(
      id: StoreId("store-5"),
      name: "Tapioca House",
      address: "555 Mission St, San Francisco, CA",
      lat: 37.7880,
      lng: -122.3995,
      image_url: option.Some("https://example.com/tapioca-house.jpg"),
      average_rating: option.Some(4.6),
    ),
  ]
}

/// Haversine distance calculation between two points in kilometers
fn haversine_distance(lat1: Float, lng1: Float, lat2: Float, lng2: Float) -> Float {
  let earth_radius = 6371.0 // km

  let d_lat = degrees_to_radians(lat2 -. lat1)
  let d_lng = degrees_to_radians(lng2 -. lng1)

  let sin_d_lat_2 = trig.sin(d_lat /. 2.0)
  let sin_d_lng_2 = trig.sin(d_lng /. 2.0)
  let cos_lat1 = trig.cos(degrees_to_radians(lat1))
  let cos_lat2 = trig.cos(degrees_to_radians(lat2))

  let a =
    sin_d_lat_2 *. sin_d_lat_2
    +. cos_lat1 *. cos_lat2 *. sin_d_lng_2 *. sin_d_lng_2

  2.0 *. earth_radius *. trig.asin(trig.sqrt(a))
}

fn degrees_to_radians(degrees: Float) -> Float {
  degrees *. { trig.pi() /. 180.0 }
}

/// Filter stores by radius from a center point
fn filter_by_radius(
  stores: List(Store),
  lat: Float,
  lng: Float,
  radius: Float,
) -> List(Store) {
  list.filter(stores, fn(store) {
    let distance = haversine_distance(lat, lng, store.lat, store.lng)
    distance <=. radius
  })
}

/// Filter stores by name search (case-insensitive substring match)
fn filter_by_name(stores: List(Store), query: String) -> List(Store) {
  let query_lower = string.lowercase(query)
  list.filter(stores, fn(store) {
    string.contains(string.lowercase(store.name), query_lower)
  })
}

/// Sort stores by the specified criteria
fn sort_stores(stores: List(Store), sort: SortBy, center: Option(#(Float, Float))) -> List(Store) {
  case sort {
    RatingDesc -> {
      list.sort(stores, fn(a, b) {
        let a_rating = option.unwrap(a.average_rating, 0.0)
        let b_rating = option.unwrap(b.average_rating, 0.0)
        float.compare(b_rating, a_rating)
      })
    }
    RatingAsc -> {
      list.sort(stores, fn(a, b) {
        let a_rating = option.unwrap(a.average_rating, 0.0)
        let b_rating = option.unwrap(b.average_rating, 0.0)
        float.compare(a_rating, b_rating)
      })
    }
    Name -> {
      list.sort(stores, fn(a, b) {
        string.compare(string.lowercase(a.name), string.lowercase(b.name))
      })
    }
    Distance -> {
      case center {
        option.Some(#(lat, lng)) -> {
          list.sort(stores, fn(a, b) {
            let dist_a = haversine_distance(lat, lng, a.lat, a.lng)
            let dist_b = haversine_distance(lat, lng, b.lat, b.lng)
            float.compare(dist_a, dist_b)
          })
        }
        option.None -> {
          // Fall back to name sort if no center point provided
          list.sort(stores, fn(a, b) {
            string.compare(string.lowercase(a.name), string.lowercase(b.name))
          })
        }
      }
    }
  }
}

/// Paginate a list of items
fn paginate(items: List(a), page: Int, limit: Int) -> #(List(a), PaginationMeta) {
  let total = list.length(items)
  let total_pages = int.max(1, { total + limit - 1 } / limit)
  let page = int.clamp(page, 1, total_pages)
  let offset = { page - 1 } * limit

  let paginated =
    items
    |> list.drop(offset)
    |> list.take(limit)

  let meta = PaginationMeta(total, page, limit, total_pages)
  #(paginated, meta)
}

/// List stores with filtering, sorting, and pagination
pub fn list_stores(params: ListStoresParams) -> ListStoresResult {
  let stores = mock_stores()

  // Apply location filter if all params provided
  let stores = case params.lat, params.lng, params.radius {
    option.Some(lat), option.Some(lng), option.Some(radius) -> {
      filter_by_radius(stores, lat, lng, radius)
    }
    _, _, _ -> stores
  }

  // Apply name search filter
  let stores = case params.q {
    option.Some(q) -> filter_by_name(stores, q)
    option.None -> stores
  }

  // Determine sort center point for distance sorting
  let center = case params.lat, params.lng {
    option.Some(lat), option.Some(lng) -> option.Some(#(lat, lng))
    _, _ -> option.None
  }

  // Apply sorting
  let stores = sort_stores(stores, params.sort, center)

  // Apply pagination
  let #(paginated, meta) = paginate(stores, params.page, params.limit)

  ListStoresResult(data: paginated, meta: meta)
}

/// Encode a Store to JSON
pub fn encode_store(store: Store) -> json.Json {
  json.object([
    #("id", json.string(case store.id { StoreId(s) -> s })),
    #("name", json.string(store.name)),
    #("address", json.string(store.address)),
    #("lat", json.float(store.lat)),
    #("lng", json.float(store.lng)),
    #(
      "image_url",
      case store.image_url {
        option.Some(url) -> json.string(url)
        option.None -> json.null()
      },
    ),
    #(
      "average_rating",
      case store.average_rating {
        option.Some(rating) -> json.float(rating)
        option.None -> json.null()
      },
    ),
  ])
}

/// Encode ListStoresResult to JSON
pub fn encode_result(result: ListStoresResult) -> json.Json {
  json.object([
    #("data", json.array(result.data, encode_store)),
    #(
      "meta",
      json.object([
        #("total", json.int(result.meta.total)),
        #("page", json.int(result.meta.page)),
        #("limit", json.int(result.meta.limit)),
        #("total_pages", json.int(result.meta.total_pages)),
      ]),
    ),
  ])
}

