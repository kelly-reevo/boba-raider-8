/// Drink ratings database module (unit-21)
/// Data access layer for drink ratings

import gleam/list
import gleam/option.{Some, None}
import shared.{
  type DrinkRating, type PaginatedResponse,
  Drink, DrinkRating, PaginatedResponse, Store, PaginationMeta,
}

/// Get paginated drink ratings for a user with drink and store details
pub fn get_user_drink_ratings(
  _user_id: String,
  page: Int,
  limit: Int,
) -> PaginatedResponse(DrinkRating) {
  // Stub: In production, this queries the database
  // Returns sample data for development
  let sample_ratings = get_sample_ratings()
  let total = list.length(sample_ratings)
  let total_pages = case total % limit {
    0 -> total / limit
    _ -> total / limit + 1
  }

  let offset = {page - 1} * limit
  let paginated_data = sample_ratings
    |> list.drop(offset)
    |> list.take(limit)

  PaginatedResponse(
    data: paginated_data,
    meta: PaginationMeta(
      total: total,
      page: page,
      limit: limit,
      total_pages: total_pages,
    ),
  )
}

/// Sample data for development/testing
fn get_sample_ratings() -> List(DrinkRating) {
  [
    DrinkRating(
      id: "rating-1",
      overall_score: 4.5,
      sweetness: 3.0,
      boba_texture: 4.5,
      tea_strength: 4.0,
      review_text: Some("Great milk tea, perfect boba texture!"),
      created_at: "2024-01-15T10:30:00Z",
      updated_at: "2024-01-15T10:30:00Z",
      drink: Drink(
        id: "drink-1",
        name: "Classic Milk Tea",
        tea_type: "Black Tea",
        image_url: Some("https://example.com/drink1.jpg"),
        store: Store(id: "store-1", name: "Boba Paradise"),
      ),
    ),
    DrinkRating(
      id: "rating-2",
      overall_score: 3.5,
      sweetness: 5.0,
      boba_texture: 3.0,
      tea_strength: 2.5,
      review_text: None,
      created_at: "2024-01-10T14:20:00Z",
      updated_at: "2024-01-10T14:20:00Z",
      drink: Drink(
        id: "drink-2",
        name: "Taro Milk Tea",
        tea_type: "Milk Tea",
        image_url: None,
        store: Store(id: "store-2", name: "Tea Station"),
      ),
    ),
  ]
}
