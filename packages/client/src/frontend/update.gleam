import frontend/model.{type Model, Model, RatingsError, RatingsLoaded}
import frontend/msg.{type Msg}
import lustre/effect.{type Effect}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    msg.Increment -> #(Model(..model, count: model.count + 1), effect.none())
    msg.Decrement -> #(Model(..model, count: model.count - 1), effect.none())
    msg.Reset -> #(Model(..model, count: 0), effect.none())
    msg.RatingsLoaded(summary) -> #(
      Model(..model, ratings: RatingsLoaded(summary)),
      effect.none(),
    )
    msg.RatingsFetchError(message) -> #(
      Model(..model, ratings: RatingsError(message)),
      effect.none(),
    )
  }
}
