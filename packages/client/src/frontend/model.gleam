/// Application state

import frontend/rating_model.{type RatingForm}
import gleam/option.{type Option, None}

pub type Model {
  Model(
    count: Int,
    error: String,
    rating_modal: Option(RatingForm),
    selected_drink_id: Option(String),
    selected_drink_name: String,
  )
}

pub fn default() -> Model {
  Model(
    count: 0,
    error: "",
    rating_modal: None,
    selected_drink_id: None,
    selected_drink_name: "",
  )
}
