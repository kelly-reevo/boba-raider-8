/// Drink Detail Update - State transitions for drink detail page

import gleam/list
import gleam/option.{None}
import frontend/drink_detail_model.{
  type DrinkDetailModel, type DrinkDetailState, DrinkDetailModel,
  type RatingAggregates, RatingAggregates,
  LoadingDrink, LoadingDetails, Populated, EmptyReviews, DrinkNotFound, LoadError,
  has_no_reviews
}
import frontend/drink_detail_msg.{type DrinkDetailMsg}
import frontend/drink_detail_effects
import lustre/effect.{type Effect}

/// Update function for drink detail page
pub fn update(
  model: DrinkDetailModel,
  msg: DrinkDetailMsg,
) -> #(DrinkDetailModel, Effect(DrinkDetailMsg)) {
  case msg {
    // Initialize loading for a drink
    drink_detail_msg.LoadDrinkDetail(drink_id) -> {
      let new_model = DrinkDetailModel(
        drink_id: drink_id,
        state: LoadingDrink,
      )
      #(new_model, drink_detail_effects.load_drink_detail(drink_id))
    }

    // Drink loaded successfully - transition to loading details
    drink_detail_msg.DrinkLoaded(drink) -> {
      let new_state = case model.state {
        LoadingDrink -> LoadingDetails(drink: drink)
        _ -> LoadingDetails(drink: drink)
      }
      #(DrinkDetailModel(..model, state: new_state), effect.none())
    }

    // Aggregates loaded - check if we can transition to populated or empty
    drink_detail_msg.AggregatesLoaded(aggregates) -> {
      let new_state = case model.state {
        LoadingDetails(drink:) -> {
          case has_no_reviews(aggregates) {
            True -> EmptyReviews(drink:, aggregates:)
            False -> {
              // Still waiting for reviews - stay in loading state
              // The aggregates will need to be stored temporarily or refetched
              // For simplicity, we stay in LoadingDetails and let reviews complete it
              LoadingDetails(drink:)
            }
          }
        }
        Populated(drink:, reviews:, ..) -> {
          // If already populated with reviews, update aggregates
          Populated(drink:, aggregates:, reviews:)
        }
        _ -> model.state
      }
      #(DrinkDetailModel(..model, state: new_state), effect.none())
    }

    // Reviews loaded - complete the populated state
    drink_detail_msg.ReviewsLoaded(reviews) -> {
      let new_state = case model.state {
        LoadingDetails(drink:) -> {
          // We have drink and reviews but no aggregates yet
          // Create placeholder aggregates or stay loading
          // For simplicity, create empty aggregates that will be updated
          let placeholder_aggregates = drink_detail_model.RatingAggregates(
            drink_id: drink.id,
            overall_rating: None,
            sweetness: None,
            boba_texture: None,
            tea_strength: None,
            count: list.length(reviews),
          )
          case list.is_empty(reviews) {
            True -> EmptyReviews(drink:, aggregates: placeholder_aggregates)
            False -> Populated(drink:, aggregates: placeholder_aggregates, reviews:)
          }
        }
        Populated(drink:, aggregates:, ..) -> {
          Populated(drink:, aggregates:, reviews:)
        }
        EmptyReviews(drink:, aggregates:) -> {
          case list.is_empty(reviews) {
            True -> EmptyReviews(drink:, aggregates:)
            False -> Populated(drink:, aggregates:, reviews:)
          }
        }
        _ -> model.state
      }
      #(DrinkDetailModel(..model, state: new_state), effect.none())
    }

    // Handle drink not found (404)
    drink_detail_msg.DrinkLoadFailed("Drink not found") -> {
      #(DrinkDetailModel(..model, state: DrinkNotFound(model.drink_id)), effect.none())
    }

    // Handle aggregates/reviews 404 (drink doesn't exist)
    drink_detail_msg.AggregatesLoadFailed("Drink not found") -> {
      #(DrinkDetailModel(..model, state: DrinkNotFound(model.drink_id)), effect.none())
    }
    drink_detail_msg.ReviewsLoadFailed("Drink not found") -> {
      #(DrinkDetailModel(..model, state: DrinkNotFound(model.drink_id)), effect.none())
    }

    // Handle network/server errors
    drink_detail_msg.DrinkLoadFailed(message) -> {
      #(DrinkDetailModel(..model, state: LoadError(message)), effect.none())
    }
    drink_detail_msg.AggregatesLoadFailed(message) -> {
      #(DrinkDetailModel(..model, state: LoadError(message)), effect.none())
    }
    drink_detail_msg.ReviewsLoadFailed(message) -> {
      #(DrinkDetailModel(..model, state: LoadError(message)), effect.none())
    }

    // User actions - these are handled by parent/app level
    drink_detail_msg.AddRatingClicked(_) -> {
      // Navigation handled by parent
      #(model, effect.none())
    }
    drink_detail_msg.BackToStoreClicked(_) -> {
      // Navigation handled by parent
      #(model, effect.none())
    }

    // Retry loading after error
    drink_detail_msg.RetryLoad -> {
      let new_model = DrinkDetailModel(..model, state: LoadingDrink)
      #(new_model, drink_detail_effects.load_drink_detail(model.drink_id))
    }
  }
}
