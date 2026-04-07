/// Application messages

import shared.{type RatingsSummary}

pub type Msg {
  Increment
  Decrement
  Reset
  RatingsLoaded(summary: RatingsSummary)
  RatingsFetchError(message: String)
}
