/// State update functions

import frontend/effects
import frontend/model.{
  type Model, type StoreDetailModel,
  Model, StoreDetailModel, StoreData, Loading, Loaded, Error as LoadError,
  StoreDetail, Home,
}
import frontend/msg.{type Msg, type StoreDetailMsg, NavigateToHome,
  NavigateToStoreDetail, StoreDetailMsg, ReceivedStore, ReceivedDrinks,
  ReceivedRatings, ClickedAddDrink, ClickedBack}
import lustre/effect.{type Effect}
import shared

/// Main update function
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    NavigateToHome -> {
      #(Model(..model, current_page: Home), effect.none())
    }

    NavigateToStoreDetail(store_id) -> {
      let new_model = Model(..model, current_page: StoreDetail(store_id))
      #(new_model, effects.fetch_store_detail_data(store_id))
    }

    StoreDetailMsg(submsg) -> {
      case model.current_page {
        StoreDetail(_) -> {
          // For now, store detail state is ephemeral - in a real app
          // we'd track it in the Model. For simplicity, we just return effects
          // and let the view handle the transient state via local handling.
          #(model, handle_store_detail_effect(submsg))
        }
        _ -> #(model, effect.none())
      }
    }
  }
}

/// Handle effects for store detail messages
fn handle_store_detail_effect(msg: StoreDetailMsg) -> Effect(Msg) {
  case msg {
    ClickedAddDrink -> {
      // Navigate to add drink page (not implemented in this unit)
      effect.none()
    }
    ClickedBack -> {
      // Navigation handled by parent update
      effect.none()
    }
    _ -> effect.none()
  }
}

/// Update a StoreDetailModel with new data
/// This is used by the component to maintain local state
pub fn update_store_detail(
  model: StoreDetailModel,
  msg: StoreDetailMsg,
) -> #(StoreDetailModel, Effect(Msg)) {
  case msg {
    ReceivedStore(result) -> {
      case result {
        Ok(store) -> {
          let new_data = case model.data {
            Loading -> Loaded(StoreData(store, [], []))
            Loaded(existing) -> Loaded(StoreData(store, existing.drinks, existing.ratings))
            LoadError(_) -> Loaded(StoreData(store, [], []))
          }
          #(StoreDetailModel(..model, data: new_data), effect.none())
        }
        Error(e) -> #(StoreDetailModel(..model, data: LoadError(e)), effect.none())
      }
    }

    ReceivedDrinks(result) -> {
      case result {
        Ok(drinks) -> {
          let new_data = case model.data {
            Loading -> {
              // Partial data case - shouldn't happen in normal flow
              // but we handle it gracefully
              LoadError(shared.InternalError("Store data not loaded yet"))
            }
            Loaded(existing) -> Loaded(StoreData(existing.store, drinks, existing.ratings))
            LoadError(e) -> LoadError(e)
          }
          #(StoreDetailModel(..model, data: new_data), effect.none())
        }
        Error(e) -> #(StoreDetailModel(..model, data: LoadError(e)), effect.none())
      }
    }

    ReceivedRatings(result) -> {
      case result {
        Ok(ratings) -> {
          let new_data = case model.data {
            Loading -> {
              LoadError(shared.InternalError("Store data not loaded yet"))
            }
            Loaded(existing) -> Loaded(StoreData(existing.store, existing.drinks, ratings))
            LoadError(e) -> LoadError(e)
          }
          #(StoreDetailModel(..model, data: new_data), effect.none())
        }
        Error(e) -> #(StoreDetailModel(..model, data: LoadError(e)), effect.none())
      }
    }

    _ -> #(model, effect.none())
  }
}
