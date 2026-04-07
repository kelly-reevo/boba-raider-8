import frontend/effects
import frontend/model.{type Model, Model, StoreDetailPage}
import frontend/msg.{type Msg}
import gleam/option.{None, Some}
import lustre/effect.{type Effect}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    msg.OnRouteChange(page) -> handle_route_change(model, page)
    msg.GotStore(result) -> handle_got_store(model, result)
    msg.GotDrinks(result) -> handle_got_drinks(model, result)
  }
}

fn handle_route_change(
  _model: Model,
  page: model.Page,
) -> #(Model, Effect(Msg)) {
  case page {
    StoreDetailPage(store_id) -> #(
      Model(
        page: page,
        store: None,
        drinks: [],
        loading: True,
        error: "",
      ),
      effects.fetch_store_detail(store_id),
    )
    _ -> #(
      Model(page: page, store: None, drinks: [], loading: False, error: ""),
      effect.none(),
    )
  }
}

fn handle_got_store(model: Model, result) -> #(Model, Effect(Msg)) {
  case result {
    Ok(store) -> {
      let loading = model.drinks == []
      #(Model(..model, store: Some(store), loading: loading), effect.none())
    }
    Error(_) -> #(
      Model(..model, loading: False, error: "Failed to load store details"),
      effect.none(),
    )
  }
}

fn handle_got_drinks(model: Model, result) -> #(Model, Effect(Msg)) {
  case result {
    Ok(drinks) -> {
      let loading = model.store == None
      #(Model(..model, drinks: drinks, loading: loading), effect.none())
    }
    Error(_) -> #(
      Model(..model, loading: False, error: "Failed to load drink menu"),
      effect.none(),
    )
  }
}
