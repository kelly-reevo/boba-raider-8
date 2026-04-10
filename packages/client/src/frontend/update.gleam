import frontend/model.{type Model, Model}
import frontend/msg.{type Msg}
import frontend/rating_model
import frontend/rating_msg
import frontend/rating_update
import gleam/option.{None, Some}
import lustre/effect.{type Effect, none, map}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    msg.Increment -> #(Model(..model, count: model.count + 1), none())
    msg.Decrement -> #(Model(..model, count: model.count - 1), none())
    msg.Reset -> #(Model(..model, count: 0), none())

    msg.OpenRatingModal(drink_id, drink_name) -> {
      let form = rating_model.new(drink_id)
      let new_model = Model(
        ..model,
        rating_modal: Some(form),
        selected_drink_id: Some(drink_id),
        selected_drink_name: drink_name,
      )
      #(new_model, none())
    }

    msg.CloseRatingModal -> {
      let new_model = Model(..model, rating_modal: None)
      #(new_model, none())
    }

    msg.RatingFormMsg(rating_msg) -> {
      case model.rating_modal {
        Some(form) -> {
          let #(new_form, fx) = rating_update.update(form, rating_msg)

          // Handle modal close actions
          let final_model = case rating_msg {
            rating_msg.RatingModalClosed -> Model(..model, rating_modal: None)
            rating_msg.RatingSubmitSuccess(_) -> {
              // Keep modal open to show success state, or close after delay
              Model(..model, rating_modal: Some(new_form))
            }
            _ -> Model(..model, rating_modal: Some(new_form))
          }

          let wrapped_fx = map(fx, msg.RatingFormMsg)
          #(final_model, wrapped_fx)
        }
        None -> #(model, none())
      }
    }
  }
}
