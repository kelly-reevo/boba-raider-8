import gleam/int
import gleam/list
import gleam/option.{None, Some}
import shared.{
  type AppError, type PaginatedResponse, type RatingWithStore,
  InvalidInput, PaginatedResponse, PaginationMeta, RatingWithStore, StoreSummary,
}

/// Simulated database of ratings.
/// In production, this would be a real database connection.
pub type Db {
  Db
}

/// Get the database connection.
pub fn get_db() -> Db {
  Db
}

/// List ratings with store info for a specific user.
/// Results are ordered by created_at descending (newest first).
pub fn list_user_ratings_with_stores(
  _db: Db,
  _user_id: String,
  page: Int,
  limit: Int,
) -> Result(PaginatedResponse(RatingWithStore), AppError) {
  // Validate pagination params
  case page < 1 || limit < 1 || limit > 100 {
    True -> Error(InvalidInput("Invalid page or limit parameters"))
    False -> {
      // Get all ratings for this user (simulated lookup)
      // Data is already ordered by created_at descending
      let all_ratings = get_user_ratings()
      let total = list.length(all_ratings)

      // Calculate pagination
      let total_pages = case total % limit {
        0 -> total / limit
        _ -> total / limit + 1
      }

      // Apply pagination (skip offset, take limit)
      let offset = { page - 1 } * limit
      let paginated_data =
        all_ratings
        |> list.drop(offset)
        |> list.take(limit)

      let meta = PaginationMeta(
        total: total,
        page: page,
        limit: limit,
        total_pages: int.max(total_pages, 1),
      )

      Ok(PaginatedResponse(data: paginated_data, meta: meta))
    }
  }
}

fn get_user_ratings() -> List(RatingWithStore) {
  // Sample data already sorted by created_at descending
  let store1 =
    StoreSummary(
      id: "store_1",
      name: "Boba Paradise",
      address: "123 Main St, San Francisco, CA",
      image_url: Some("https://example.com/boba1.jpg"),
    )

  let store2 =
    StoreSummary(
      id: "store_2",
      name: "Tea Station",
      address: "456 Market St, San Francisco, CA",
      image_url: None,
    )

  // Data is pre-sorted by created_at descending (newest first)
  [
    RatingWithStore(
      id: "rating_1",
      overall_score: 4.5,
      review_text: Some("Great bubble tea! Love the taro flavor."),
      created_at: "2024-01-15T10:30:00Z",
      updated_at: "2024-01-15T10:30:00Z",
      store: store1,
    ),
    RatingWithStore(
      id: "rating_2",
      overall_score: 3.0,
      review_text: None,
      created_at: "2024-01-10T14:20:00Z",
      updated_at: "2024-01-10T14:20:00Z",
      store: store2,
    ),
  ]
}
