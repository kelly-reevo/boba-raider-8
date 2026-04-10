/// Rating form update logic

import frontend/rating_model.{type RatingForm}
import frontend/rating_msg.{type RatingMsg}
import frontend/rating_effects
import gleam/option.{None, Some}
import lustre/effect.{type Effect, none}

pub fn update(
  form: RatingForm,
  msg: RatingMsg,
) -> #(RatingForm, Effect(RatingMsg)) {
  case msg {
    rating_msg.RatingOverallChanged(score) -> {
      let new_form = rating_model.set_overall(form, score)
      #(new_form, none())
    }

    rating_msg.RatingSweetnessChanged(score) -> {
      let new_form = rating_model.set_sweetness(form, score)
      #(new_form, none())
    }

    rating_msg.RatingBobaTextureChanged(score) -> {
      let new_form = rating_model.set_boba_texture(form, score)
      #(new_form, none())
    }

    rating_msg.RatingTeaStrengthChanged(score) -> {
      let new_form = rating_model.set_tea_strength(form, score)
      #(new_form, none())
    }

    rating_msg.RatingReviewTextChanged(text) -> {
      let new_form = rating_model.set_review_text(form, text)
      #(new_form, none())
    }

    rating_msg.RatingSubmitClicked -> {
      case rating_model.can_submit(form) {
        True -> {
          let submitting_form = rating_model.set_submitting(form)
          #(submitting_form, rating_effects.submit_rating(submitting_form))
        }
        False -> {
          let error_form =
            rating_model.set_error(form, "Please select an overall rating")
          #(error_form, none())
        }
      }
    }

    rating_msg.RatingSubmitSuccess(_rating_id) -> {
      let success_form = rating_model.set_success(form)
      #(success_form, none())
    }

    rating_msg.RatingSubmitError(error) -> {
      let error_form = rating_model.set_error(form, error)
      #(error_form, none())
    }

    rating_msg.RatingModalClosed -> {
      #(form, none())
    }

    rating_msg.RatingResetForm -> {
      let reset_form =
        rating_model.new(form.drink_id)
        |> rating_model.set_submitting
      let cleared_form = case form.existing_rating_id {
        Some(id) -> rating_model.RatingForm(..reset_form, existing_rating_id: Some(id))
        None -> reset_form
      }
      #(cleared_form, none())
    }
  }
}
