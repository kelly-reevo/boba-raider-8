/// Rating form state management

import gleam/option.{type Option, None, Some}

// Local type definitions (replicated from shared package for type safety)
pub type RatingScores {
  RatingScores(
    overall: Int,
    sweetness: Int,
    boba_texture: Int,
    tea_strength: Int,
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

pub type FormStatus {
  FormEditing
  FormSubmitting
  FormSuccess
  FormError(String)
}

pub type RatingForm {
  RatingForm(
    drink_id: String,
    existing_rating_id: Option(String),
    scores: RatingScores,
    review_text: String,
    status: FormStatus,
  )
}

fn default_scores() -> RatingScores {
  RatingScores(overall: 0, sweetness: 3, boba_texture: 3, tea_strength: 3)
}

pub fn new(drink_id: String) -> RatingForm {
  RatingForm(
    drink_id: drink_id,
    existing_rating_id: None,
    scores: default_scores(),
    review_text: "",
    status: FormEditing,
  )
}

pub fn from_existing(
  drink_id: String,
  rating_id: String,
  scores: RatingScores,
  review_text: String,
) -> RatingForm {
  RatingForm(
    drink_id: drink_id,
    existing_rating_id: Some(rating_id),
    scores: scores,
    review_text: review_text,
    status: FormEditing,
  )
}

pub fn set_overall(form: RatingForm, score: Int) -> RatingForm {
  let new_scores = RatingScores(..form.scores, overall: score)
  RatingForm(..form, scores: new_scores, status: FormEditing)
}

pub fn set_sweetness(form: RatingForm, score: Int) -> RatingForm {
  let new_scores = RatingScores(..form.scores, sweetness: score)
  RatingForm(..form, scores: new_scores, status: FormEditing)
}

pub fn set_boba_texture(form: RatingForm, score: Int) -> RatingForm {
  let new_scores = RatingScores(..form.scores, boba_texture: score)
  RatingForm(..form, scores: new_scores, status: FormEditing)
}

pub fn set_tea_strength(form: RatingForm, score: Int) -> RatingForm {
  let new_scores = RatingScores(..form.scores, tea_strength: score)
  RatingForm(..form, scores: new_scores, status: FormEditing)
}

pub fn set_review_text(form: RatingForm, text: String) -> RatingForm {
  RatingForm(..form, review_text: text, status: FormEditing)
}

pub fn set_submitting(form: RatingForm) -> RatingForm {
  RatingForm(..form, status: FormSubmitting)
}

pub fn set_success(form: RatingForm) -> RatingForm {
  RatingForm(..form, status: FormSuccess)
}

pub fn set_error(form: RatingForm, error: String) -> RatingForm {
  RatingForm(..form, status: FormError(error))
}

pub fn is_submitting(form: RatingForm) -> Bool {
  case form.status {
    FormSubmitting -> True
    _ -> False
  }
}

pub fn get_validation_error(form: RatingForm) -> Option(String) {
  let scores: RatingScores = form.scores
  case scores.overall {
    0 -> Some("Please select an overall rating")
    _ -> None
  }
}

pub fn to_rating_input(form: RatingForm) -> RatingInput {
  let scores: RatingScores = form.scores
  RatingInput(
    overall: scores.overall,
    sweetness: scores.sweetness,
    boba_texture: scores.boba_texture,
    tea_strength: scores.tea_strength,
    review_text: form.review_text,
  )
}

pub fn can_submit(form: RatingForm) -> Bool {
  let scores: RatingScores = form.scores
  scores.overall >= 1 && !is_submitting(form)
}
