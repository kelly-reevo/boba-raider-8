/// Boba Store - Unified interface for drink and rating operations
/// Coordinates drink_store and rating_service actors for use by tests and handlers

import drink_store.{type DrinkStore}
import gleam/option.{type Option, None, Some}
import rating_service.{type RatingService}

/// Combined store reference holding both drink and rating services
pub type BobaStore {
  BobaStore(
    drink_store: DrinkStore,
    rating_service: RatingService,
  )
}

/// Drink record returned from create_drink
pub type Drink {
  Drink(
    id: String,
    name: String,
    description: String,
    price: Float,
  )
}

/// Rating record returned from submit_rating
pub type Rating {
  Rating(
    id: String,
    drink_id: String,
    overall_rating: Float,
    sweetness: Float,
    boba_texture: Float,
    tea_strength: Float,
  )
}

/// Start both drink_store and rating_service actors
/// Returns a BobaStore containing references to both services
pub fn start() -> Result(BobaStore, String) {
  // Start drink store actor
  case drink_store.start() {
    Error(err) -> Error("Failed to start drink store: " <> err)
    Ok(drink_store_ref) -> {
      // Start rating service actor with dependency on drink store
      case rating_service.start(drink_store_ref) {
        Error(err) -> Error("Failed to start rating service: " <> err)
        Ok(rating_service_ref) -> {
          Ok(BobaStore(
            drink_store: drink_store_ref,
            rating_service: rating_service_ref,
          ))
        }
      }
    }
  }
}

/// Create a new drink in the store
/// Returns the created drink with generated ID
pub fn create_drink(
  store: BobaStore,
  name: String,
  description: String,
  price: Float,
) -> Result(Drink, String) {
  // For drink creation, we need a store_id. Since the tests don't provide one,
  // we create a drink using a placeholder store_id for the internal storage,
  // then return a simplified Drink record
  let input = drink_store.CreateDrinkInput(
    store_id: "test-store",
    name: name,
    description: Some(description),
    base_tea_type: None,
    price: Some(price),
  )

  case drink_store.create_drink(store.drink_store, input) {
    Error(err) -> Error(err)
    Ok(record) -> {
      Ok(Drink(
        id: record.id,
        name: record.name,
        description: case record.description { Some(d) -> d None -> "" },
        price: case record.price { Some(p) -> p None -> 0.0 },
      ))
    }
  }
}

/// Submit a rating for a drink
/// Creates a rating record with the rating service
pub fn submit_rating(
  store: BobaStore,
  drink_id: String,
  overall_rating: Float,
  sweetness: Float,
  boba_texture: Float,
  tea_strength: Float,
) -> Result(Rating, String) {
  // Pass float ratings directly to rating service
  let input = rating_service.CreateRatingInput(
    drink_id: drink_id,
    reviewer_name: None,
    overall_rating: overall_rating,
    sweetness: sweetness,
    boba_texture: boba_texture,
    tea_strength: tea_strength,
    review_text: None,
  )

  case rating_service.create_rating(store.rating_service, input) {
    Error(err) -> Error(err)
    Ok(record) -> {
      Ok(Rating(
        id: record.id,
        drink_id: record.drink_id,
        overall_rating: record.overall_rating,
        sweetness: record.sweetness,
        boba_texture: record.boba_texture,
        tea_strength: record.tea_strength,
      ))
    }
  }
}

/// Get aggregate ratings for a drink
/// Returns rating averages and count, or error if drink not found
pub fn get_drink_aggregates(
  store: BobaStore,
  drink_id: String,
) -> Result(AggregateRatings, String) {
  // First verify the drink exists
  case drink_store.get_drink_by_id(store.drink_store, drink_id) {
    Error(_) -> Error("Drink not found")
    Ok(_) -> {
      // Drink exists, get aggregates from rating service
      case rating_service.get_rating_aggregate(store.rating_service, drink_id) {
        Error(err) -> Error(err)
        Ok(aggregate) -> {
          // Convert from RatingAggregate to AggregateRatings with proper null handling
          let has_ratings = aggregate.total_reviews > 0

          Ok(AggregateRatings(
            drink_id: aggregate.drink_id,
            overall_rating: case has_ratings {
              True -> Some(aggregate.average_overall)
              False -> None
            },
            sweetness: case has_ratings {
              True -> Some(aggregate.average_sweetness)
              False -> None
            },
            boba_texture: case has_ratings {
              True -> Some(aggregate.average_boba_texture)
              False -> None
            },
            tea_strength: case has_ratings {
              True -> Some(aggregate.average_tea_strength)
              False -> None
            },
            count: aggregate.total_reviews,
          ))
        }
      }
    }
  }
}

/// Aggregate ratings output type for API responses
pub type AggregateRatings {
  AggregateRatings(
    drink_id: String,
    overall_rating: Option(Float),
    sweetness: Option(Float),
    boba_texture: Option(Float),
    tea_strength: Option(Float),
    count: Int,
  )
}

