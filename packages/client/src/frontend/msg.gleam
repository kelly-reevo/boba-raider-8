/// Application messages

import frontend/rating_msg.{type RatingMsg}

pub type Msg {
  Increment
  Decrement
  Reset
  OpenRatingModal(drink_id: String, drink_name: String)
  CloseRatingModal
  RatingFormMsg(RatingMsg)
}
