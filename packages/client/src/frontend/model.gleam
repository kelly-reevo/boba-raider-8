/// Application state

import shared.{type RatingsSummary}

pub type RatingsState {
  RatingsLoading
  RatingsLoaded(summary: RatingsSummary)
  RatingsError(message: String)
}

pub type Model {
  Model(count: Int, error: String, ratings: RatingsState)
}

pub fn default() -> Model {
  Model(count: 0, error: "", ratings: RatingsLoading)
}
