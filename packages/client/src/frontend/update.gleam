import frontend/model.{type Model, Failed, Loaded, Model}
import frontend/msg.{type Msg}
import lustre/effect.{type Effect}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    msg.UserUpdatedSearch(query) -> #(
      Model(..model, search_query: query),
      effect.none(),
    )
    msg.ApiReturnedStores(Ok(stores)) -> #(
      Model(..model, stores: stores, load_state: Loaded),
      effect.none(),
    )
    msg.ApiReturnedStores(Error(err)) -> #(
      Model(..model, load_state: Failed(err)),
      effect.none(),
    )
  }
}
