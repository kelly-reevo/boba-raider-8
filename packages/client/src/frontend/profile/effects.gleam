import frontend/profile/msg.{type Msg}
import lustre/effect.{type Effect}
import shared.{
  DrinkRating, StoreRating, User, UserProfile, UserStats,
}

/// Fetch current user profile
pub fn fetch_user_profile() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // Simulated API call - in production this would use lustre_http
    // let url = api_base <> "/users/me"
    // http.get(url, expect: expect_json(profile_decoder, msg.ProfileLoaded, msg.ProfileLoadFailed))

    // Simulated response for development
    let user = User(
      id: "user-123",
      username: "boba_lover",
      email: "boba@example.com",
      avatar_url: "/static/avatar-default.png",
      created_at: "2024-01-15T08:30:00Z",
    )
    let stats = UserStats(
      total_store_ratings: 12,
      total_drink_ratings: 45,
      average_store_rating: 4.2,
      average_drink_rating: 4.5,
    )
    let profile = UserProfile(user: user, stats: stats)

    dispatch(msg.ProfileLoaded(profile))
  })
}

/// Fetch store ratings for current user
pub fn fetch_store_ratings(page page: Int, per_page _per_page: Int) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // Simulated API call - in production: GET /api/users/me/ratings/stores?page=X&per_page=Y
    // let url = api_base <> "/users/me/ratings/stores?page=" <> int.to_string(page) <> "&per_page=" <> int.to_string(per_page)

    // Simulated response for development
    let ratings = case page {
      1 -> [
        StoreRating(
          id: "sr-1",
          store_id: "store-1",
          store_name: "Boba Bliss Downtown",
          rating: 5,
          review: "Amazing atmosphere and friendly staff!",
          created_at: "2024-03-10T14:30:00Z",
        ),
        StoreRating(
          id: "sr-2",
          store_id: "store-2",
          store_name: "Tea Time Cafe",
          rating: 4,
          review: "Good selection, but can get crowded on weekends.",
          created_at: "2024-03-05T10:15:00Z",
        ),
        StoreRating(
          id: "sr-3",
          store_id: "store-3",
          store_name: "Milk Tea Magic",
          rating: 3,
          review: "Average quality, convenient location.",
          created_at: "2024-02-28T16:45:00Z",
        ),
      ]
      2 -> [
        StoreRating(
          id: "sr-4",
          store_id: "store-4",
          store_name: "The Boba Spot",
          rating: 5,
          review: "Best tapioca pearls in the city!",
          created_at: "2024-02-20T11:00:00Z",
        ),
      ]
      _ -> []
    }

    dispatch(msg.StoreRatingsLoaded(ratings, 4))
  })
}

/// Fetch drink ratings for current user
pub fn fetch_drink_ratings(page page: Int, per_page _per_page: Int) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // Simulated API call - in production: GET /api/users/me/ratings/drinks?page=X&per_page=Y
    // let url = api_base <> "/users/me/ratings/drinks?page=" <> int.to_string(page) <> "&per_page=" <> int.to_string(per_page)

    // Simulated response for development
    let ratings = case page {
      1 -> [
        DrinkRating(
          id: "dr-1",
          drink_id: "drink-1",
          drink_name: "Classic Milk Tea",
          store_name: "Boba Bliss Downtown",
          rating: 5,
          review: "Perfect balance of tea and milk!",
          created_at: "2024-03-10T14:35:00Z",
        ),
        DrinkRating(
          id: "dr-2",
          drink_id: "drink-2",
          drink_name: "Brown Sugar Boba",
          store_name: "Tea Time Cafe",
          rating: 5,
          review: "So sweet and creamy, absolutely love it.",
          created_at: "2024-03-08T13:20:00Z",
        ),
        DrinkRating(
          id: "dr-3",
          drink_id: "drink-3",
          drink_name: "Taro Milk Tea",
          store_name: "Milk Tea Magic",
          rating: 4,
          review: "Good taro flavor, not too artificial.",
          created_at: "2024-03-05T09:45:00Z",
        ),
      ]
      2 -> [
        DrinkRating(
          id: "dr-4",
          drink_id: "drink-4",
          drink_name: "Matcha Latte",
          store_name: "Boba Bliss Downtown",
          rating: 4,
          review: "Authentic matcha taste, well prepared.",
          created_at: "2024-03-01T15:30:00Z",
        ),
      ]
      _ -> []
    }

    dispatch(msg.DrinkRatingsLoaded(ratings, 4))
  })
}
