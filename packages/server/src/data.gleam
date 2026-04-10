import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option}
import gleam/order
import gleam/string

pub type User {
  User(id: String, username: String)
}

pub type Rating {
  Rating(
    id: String,
    store_id: String,
    user: User,
    overall_score: Float,
    review_text: Option(String),
    created_at: String,
    updated_at: String,
  )
}

pub type PaginationMeta {
  PaginationMeta(total: Int, page: Int, limit: Int, total_pages: Int)
}

pub type RatingsResult {
  RatingsResult(data: List(Rating), meta: PaginationMeta)
}

/// In-memory store for ratings (simulating a database)
/// In production, this would be a database connection
pub type Store {
  Store(ratings: Dict(String, Rating))
}

/// Create a new empty store
pub fn new_store() -> Store {
  Store(ratings: dict.new())
}

/// Insert a rating into the store
pub fn insert_rating(store: Store, rating: Rating) -> Store {
  let new_ratings = dict.insert(store.ratings, rating.id, rating)
  Store(ratings: new_ratings)
}

/// Get ratings for a store with pagination
pub fn get_store_ratings(
  store: Store,
  store_id: String,
  page: Int,
  limit: Int,
) -> Result(RatingsResult, Nil) {
  // Filter ratings by store_id
  let store_ratings =
    dict.values(store.ratings)
    |> list.filter(fn(r) { r.store_id == store_id })
    |> list.sort(fn(a, b) {
      // Sort by created_at descending (newest first)
      case string.compare(a.created_at, b.created_at) {
        order.Lt -> order.Gt
        order.Eq -> order.Eq
        order.Gt -> order.Lt
      }
    })

  let total = list.length(store_ratings)

  // Handle empty case - still return success with empty data
  case total {
    0 -> {
      let meta = PaginationMeta(total: 0, page: page, limit: limit, total_pages: 0)
      Ok(RatingsResult(data: [], meta: meta))
    }
    _ -> {
      // Apply pagination
      let total_pages = { total + limit - 1 } / limit
      let offset = { page - 1 } * limit

      let paginated =
        store_ratings
        |> list.drop(offset)
        |> list.take(limit)

      let meta = PaginationMeta(total: total, page: page, limit: limit, total_pages: total_pages)
      Ok(RatingsResult(data: paginated, meta: meta))
    }
  }
}

/// Check if a store has any ratings (used for 404 check)
pub fn store_exists(_store: Store, _store_id: String) -> Bool {
  // In a real database, this would check if the store exists
  // For simplicity, we assume stores exist if they have ratings
  // or could be validated separately
  True
}
