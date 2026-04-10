/// Application state updates

import frontend/components/store_rating_form as form
import frontend/effects
import frontend/model.{type Model, Model}
import frontend/msg.{type Msg}
import gleam/option.{None, Some}
import lustre/effect.{type Effect}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Counter messages (existing)
    msg.Increment -> #(Model(..model, count: model.count + 1), effect.none())
    msg.Decrement -> #(Model(..model, count: model.count - 1), effect.none())
    msg.Reset -> #(Model(..model, count: 0), effect.none())

    // Rating form: Open for new rating
    msg.RatingFormOpened(store_id, display_mode) -> {
      let form_model = form.init_new(store_id, display_mode)
      #(Model(..model, rating_form: Some(form_model)), effect.none())
    }

    // Rating form: Open for editing existing rating
    msg.RatingFormOpenedForEdit(store_id, rating_id, overall_score, review_text, display_mode) -> {
      let form_model = form.init_edit(store_id, rating_id, overall_score, review_text, display_mode)
      #(Model(..model, rating_form: Some(form_model)), effect.none())
    }

    // Rating form: Close
    msg.RatingFormClosed -> {
      #(Model(..model, rating_form: None), effect.none())
    }

    // Rating form: Score changed
    msg.RatingScoreChanged(score) -> {
      case model.rating_form {
        Some(form_model) -> {
          let new_form = form.StoreRatingFormModel(..form_model, overall_score: score)
          #(Model(..model, rating_form: Some(new_form)), effect.none())
        }
        None -> #(model, effect.none())
      }
    }

    // Rating form: Review text changed
    msg.RatingReviewTextChanged(text) -> {
      case model.rating_form {
        Some(form_model) -> {
          let new_form = form.StoreRatingFormModel(..form_model, review_text: text)
          #(Model(..model, rating_form: Some(new_form)), effect.none())
        }
        None -> #(model, effect.none())
      }
    }

    // Rating form: Submit
    msg.RatingFormSubmitted -> {
      case model.rating_form {
        Some(form_model) -> {
          // Validate form before submitting
          case form.is_valid(form_model) {
            True -> {
              let new_form = form.StoreRatingFormModel(
                ..form_model,
                submit_state: form.Submitting,
              )
              let effect = effects.submit_store_rating(
                form_model.store_id,
                form_model.existing_rating_id,
                form_model.overall_score,
                form_model.review_text,
              )
              #(Model(..model, rating_form: Some(new_form)), effect)
            }
            False -> {
              // Form invalid, show error without submitting
              let new_form = form.StoreRatingFormModel(
                ..form_model,
                submit_state: form.SubmitError("Please select a star rating."),
              )
              #(Model(..model, rating_form: Some(new_form)), effect.none())
            }
          }
        }
        None -> #(model, effect.none())
      }
    }

    // Rating form: Delete clicked
    msg.RatingDeleteClicked -> {
      case model.rating_form {
        Some(form_model) -> {
          case form_model.existing_rating_id {
            Some(rating_id) -> {
              let new_form = form.StoreRatingFormModel(
                ..form_model,
                submit_state: form.Submitting,
              )
              let effect = effects.delete_store_rating(form_model.store_id, rating_id)
              #(Model(..model, rating_form: Some(new_form)), effect)
            }
            None -> #(model, effect.none())
          }
        }
        None -> #(model, effect.none())
      }
    }

    // Rating created successfully
    msg.RatingCreated(_store_id) -> {
      case model.rating_form {
        Some(form_model) -> {
          let new_form = form.StoreRatingFormModel(
            ..form_model,
            submit_state: form.SubmitSuccess,
            existing_rating_id: Some("temp-rating-id"),
          )
          #(Model(..model, rating_form: Some(new_form)), effect.none())
        }
        None -> #(model, effect.none())
      }
    }

    // Rating updated successfully
    msg.RatingUpdated(_store_id) -> {
      case model.rating_form {
        Some(form_model) -> {
          let new_form = form.StoreRatingFormModel(
            ..form_model,
            submit_state: form.SubmitSuccess,
          )
          #(Model(..model, rating_form: Some(new_form)), effect.none())
        }
        None -> #(model, effect.none())
      }
    }

    // Rating deleted successfully
    msg.RatingDeleted(_store_id) -> {
      // Close the form after successful deletion
      #(Model(..model, rating_form: None), effect.none())
    }

    // Rating API error
    msg.RatingApiError(error) -> {
      case model.rating_form {
        Some(form_model) -> {
          let new_form = form.StoreRatingFormModel(
            ..form_model,
            submit_state: form.SubmitError(error),
          )
          #(Model(..model, rating_form: Some(new_form)), effect.none())
        }
        None -> #(Model(..model, error: error), effect.none())
      }
    }
  }
}
