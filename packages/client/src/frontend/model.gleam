/// Application state

import shared.{type RatingSubmission}

/// Page state for the rating form
pub type RatingPage {
  /// Form is ready for input
  FormReady
  /// Submission in progress
  Submitting
  /// Submission succeeded
  SubmitSuccess
  /// Submission failed
  SubmitError(String)
}

pub type Model {
  Model(
    count: Int,
    error: String,
    rating: RatingSubmission,
    rating_page: RatingPage,
  )
}

pub fn default() -> Model {
  Model(
    count: 0,
    error: "",
    rating: shared.empty_rating(),
    rating_page: FormReady,
  )
}
