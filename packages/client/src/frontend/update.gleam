/// Update functions for state transitions

import frontend/effects
import frontend/model.{type Model, Model, Error, Loaded, Loading, NotFound}
import frontend/msg.{type Msg}
import gleam/option.{Some}
import lustre/effect.{type Effect}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Navigation - triggers data loading
    msg.NavigateToStore(store_id) -> #(
      model.init_store_detail(store_id),
      effects.fetch_store_data(store_id),
    )

    // Store API success - update store info
    msg.StoreLoaded(store_info) -> {
      let updated_model = case model.page_state {
        Loading -> Model(..model, page_state: Loaded, store: Some(store_info))
        _ -> Model(..model, store: Some(store_info))
      }
      #(updated_model, effect.none())
    }

    // Store API 404 - show not found page
    msg.StoreLoadFailed(404) -> #(
      Model(..model, page_state: NotFound),
      effect.none(),
    )

    // Store API other error
    msg.StoreLoadFailed(_) -> #(
      Model(..model, page_state: Error("Failed to load store")),
      effect.none(),
    )

    // Drinks API success - update drinks list
    msg.DrinksLoaded(drinks) -> {
      let updated_model = case model.page_state {
        Loading -> Model(..model, page_state: Loaded, drinks: drinks)
        _ -> Model(..model, drinks: drinks)
      }
      #(updated_model, effect.none())
    }

    // Drinks API error
    msg.DrinksLoadFailed(error_msg) -> #(
      Model(..model, page_state: Error(error_msg)),
      effect.none(),
    )

    // User clicks add drink button
    msg.ClickAddDrink -> {
      // Navigation to add drink form would happen here
      #(model, effect.none())
    }

    // Legacy counter messages - maintained for backward compatibility
    msg.Increment -> #(Model(..model, count: model.count + 1), effect.none())
    msg.Decrement -> #(Model(..model, count: model.count - 1), effect.none())
    msg.Reset -> #(Model(..model, count: 0), effect.none())
  }
}

