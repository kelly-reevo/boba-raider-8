/// Update functions for the MVU cycle

import frontend/model.{type Model, Model}
import frontend/msg.{
  type Msg, LoadDrinkError, LoadDrinkRequest, LoadDrinkSuccess, LoadStoresError,
  LoadStoresRequest, LoadStoresSuccess, RetryLoadDrink, RetryLoadStores,
  SetReducedMotion, SubmitRatingError, SubmitRatingRequest, SubmitRatingSuccess,
  UpdateBobaTexture, UpdateSweetness, UpdateTeaStrength,
}
import gleam/option.{None, Some}
import lustre/effect.{type Effect}

/// Main update function
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Store list messages
    LoadStoresRequest -> {
      let new_model = Model(..model, stores_loading: True, stores_error: None)
      #(new_model, effect.none())
    }
    LoadStoresSuccess(stores) -> {
      let new_model = Model(..model, stores_loading: False, stores: stores)
      #(new_model, effect.none())
    }
    LoadStoresError(error) -> {
      let new_model = Model(..model, stores_loading: False, stores_error: Some(error))
      #(new_model, effect.none())
    }

    // Drink detail messages
    LoadDrinkRequest(_drink_id) -> {
      let new_model = Model(..model, drink_loading: True, drink_error: None)
      #(new_model, effect.none())
    }
    LoadDrinkSuccess(drink, ratings) -> {
      let new_model = Model(
        ..model,
        drink_loading: False,
        drink: Some(drink),
        drink_ratings: ratings,
      )
      #(new_model, effect.none())
    }
    LoadDrinkError(error) -> {
      let new_model = Model(..model, drink_loading: False, drink_error: Some(error))
      #(new_model, effect.none())
    }

    // Rating form messages
    UpdateSweetness(value) -> {
      let new_model = Model(..model, rating_sweetness: value)
      #(new_model, effect.none())
    }
    UpdateBobaTexture(value) -> {
      let new_model = Model(..model, rating_boba_texture: value)
      #(new_model, effect.none())
    }
    UpdateTeaStrength(value) -> {
      let new_model = Model(..model, rating_tea_strength: value)
      #(new_model, effect.none())
    }
    SubmitRatingRequest -> {
      let new_model = Model(..model, rating_submitting: True, rating_submit_error: None)
      #(new_model, effect.none())
    }
    SubmitRatingSuccess -> {
      let new_model = Model(
        ..model,
        rating_submitting: False,
        rating_sweetness: 0,
        rating_boba_texture: 0,
        rating_tea_strength: 0,
      )
      #(new_model, effect.none())
    }
    SubmitRatingError(error) -> {
      let new_model = Model(..model, rating_submitting: False, rating_submit_error: Some(error))
      #(new_model, effect.none())
    }

    // Accessibility messages
    SetReducedMotion(prefers_reduced) -> {
      let new_model = Model(..model, prefers_reduced_motion: prefers_reduced)
      #(new_model, effect.none())
    }

    // Retry actions
    RetryLoadStores -> {
      // Reset to loading state and trigger reload
      let new_model = Model(..model, stores_loading: True, stores_error: None)
      #(new_model, effect.none())
    }
    RetryLoadDrink -> {
      // Reset to loading state and trigger reload
      let new_model = Model(..model, drink_loading: True, drink_error: None)
      #(new_model, effect.none())
    }
  }
}

/// Attempt to submit rating while loading - prevents double submission
pub fn attempt_submit_while_loading(model: Model) -> #(Bool, option.Option(String)) {
  case model.rating_submitting {
    True -> #(True, Some("Submission already in progress"))
    False -> #(False, None)
  }
}
