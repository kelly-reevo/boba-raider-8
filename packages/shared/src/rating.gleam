/// Shared types for drink ratings

pub type RatingScores {
  RatingScores(
    overall: Int,
    sweetness: Int,
    boba_texture: Int,
    tea_strength: Int,
  )
}

pub type Rating {
  Rating(
    id: String,
    drink_id: String,
    user_id: String,
    scores: RatingScores,
    review_text: String,
    created_at: String,
    updated_at: String,
  )
}

pub type RatingInput {
  RatingInput(
    overall: Int,
    sweetness: Int,
    boba_texture: Int,
    tea_strength: Int,
    review_text: String,
  )
}

pub fn default_scores() -> RatingScores {
  RatingScores(overall: 0, sweetness: 3, boba_texture: 3, tea_strength: 3)
}

pub fn default_input() -> RatingInput {
  RatingInput(overall: 0, sweetness: 3, boba_texture: 3, tea_strength: 3, review_text: "")
}

pub fn is_valid_input(input: RatingInput) -> Bool {
  input.overall >= 1
  && input.overall <= 5
  && input.sweetness >= 1
  && input.sweetness <= 5
  && input.boba_texture >= 1
  && input.boba_texture <= 5
  && input.tea_strength >= 1
  && input.tea_strength <= 5
}
