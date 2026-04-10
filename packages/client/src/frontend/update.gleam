import frontend/effects
import frontend/model.{type Model, Model, DrinkDetailLoading, DrinkDetailError, DrinkDetailPopulated}
import frontend/msg.{type Msg}
import gleam/option.{None}
import lustre/effect.{type Effect}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Counter messages (legacy)
    msg.Increment -> #(Model(..model, count: model.count + 1), effect.none())
    msg.Decrement -> #(Model(..model, count: model.count - 1), effect.none())
    msg.Reset -> #(Model(..model, count: 0), effect.none())

    // Drink detail messages
    msg.LoadDrinkDetail(drink_id) -> #(
      Model(..model, drink_detail: DrinkDetailLoading),
      effects.load_drink_detail(drink_id),
    )

    msg.DrinkDetailLoaded(drink, ratings) -> #(
      Model(..model, drink_detail: DrinkDetailPopulated(drink, None, ratings)),
      effect.none(),
    )

    msg.UserRatingLoaded(user_rating) -> {
      case model.drink_detail {
        DrinkDetailPopulated(drink, _, other_ratings) -> #(
          Model(..model, drink_detail: DrinkDetailPopulated(drink, user_rating, other_ratings)),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }
    }

    msg.DrinkDetailError(error_msg) -> #(
      Model(..model, drink_detail: DrinkDetailError(error_msg)),
      effect.none(),
    )
  }
}
