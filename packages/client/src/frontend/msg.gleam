/// Application messages

pub type RatingCategory {
  Sweetness
  BobaTexture
  TeaStrength
  Overall
}

pub type Msg {
  Increment
  Decrement
  Reset
  SetRating(category: RatingCategory, value: Int)
  SubmitRating
  RatingSubmitted(Result(Nil, String))
  ResetRating
}
