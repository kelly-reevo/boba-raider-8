import gleam/option.{type Option}
import shared.{type Drink, type Rating}

import frontend/rating_model.{type RatingForm}
import gleam/option.{type Option, None}

import frontend/components/store_rating_form.{type StoreRatingFormModel}
import gleam/option.{type Option, None}

pub type Model {
  Model(
    count: Int,
    error: String,
    // Store rating form state
    rating_form: Option(StoreRatingFormModel),
  )
}

pub fn default() -> Model {
  Model(count: 0, error: "", rating_form: None)
}
