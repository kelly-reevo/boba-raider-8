import frontend/effects
import frontend/model.{type Model, Model, FormReady, SubmitError, SubmitSuccess, Submitting}
import frontend/msg.{type Msg}
import lustre/effect.{type Effect}
import shared

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    msg.Increment -> #(Model(..model, count: model.count + 1), effect.none())
    msg.Decrement -> #(Model(..model, count: model.count - 1), effect.none())
    msg.Reset -> #(Model(..model, count: 0), effect.none())

    msg.SetRating(category, value) -> {
      let clamped = clamp(value, 1, 5)
      let rating = case category {
        msg.Sweetness ->
          shared.RatingSubmission(..model.rating, sweetness: clamped)
        msg.BobaTexture ->
          shared.RatingSubmission(..model.rating, boba_texture: clamped)
        msg.TeaStrength ->
          shared.RatingSubmission(..model.rating, tea_strength: clamped)
        msg.Overall ->
          shared.RatingSubmission(..model.rating, overall: clamped)
      }
      #(Model(..model, rating: rating, rating_page: FormReady), effect.none())
    }

    msg.SubmitRating -> {
      case shared.is_rating_complete(model.rating) {
        True -> #(
          Model(..model, rating_page: Submitting),
          effects.submit_rating(model.rating),
        )
        False -> #(
          Model(..model, rating_page: SubmitError("All ratings are required")),
          effect.none(),
        )
      }
    }

    msg.RatingSubmitted(Ok(_)) -> #(
      Model(..model, rating_page: SubmitSuccess),
      effect.none(),
    )

    msg.RatingSubmitted(Error(err)) -> #(
      Model(..model, rating_page: SubmitError(err)),
      effect.none(),
    )

    msg.ResetRating -> #(
      Model(..model, rating: shared.empty_rating(), rating_page: FormReady),
      effect.none(),
    )
  }
}

fn clamp(value: Int, min: Int, max: Int) -> Int {
  case value < min {
    True -> min
    False ->
      case value > max {
        True -> max
        False -> value
      }
  }
}
