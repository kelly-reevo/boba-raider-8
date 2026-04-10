import gleam/option.{type Option}
import shared.{type Drink, type Rating}

/// Application messages

import frontend/rating_msg.{type RatingMsg}

pub type Msg {
  // Counter messages (legacy)
  Increment
  Decrement
  Reset
  OpenRatingModal(drink_id: String, drink_name: String)
  CloseRatingModal
  RatingFormMsg(RatingMsg)
}
