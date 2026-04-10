/// Rating form messages

pub type RatingMsg {
  RatingOverallChanged(Int)
  RatingSweetnessChanged(Int)
  RatingBobaTextureChanged(Int)
  RatingTeaStrengthChanged(Int)
  RatingReviewTextChanged(String)
  RatingSubmitClicked
  RatingSubmitSuccess(String)
  RatingSubmitError(String)
  RatingModalClosed
  RatingResetForm
}
