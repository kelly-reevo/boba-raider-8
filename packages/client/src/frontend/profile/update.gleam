import frontend/profile/effects
import frontend/profile/model.{type Model, Model}
import frontend/profile/msg.{type Msg}
import lustre/effect.{type Effect}
import shared.{DrinkRatingsTab, Empty, Error, Loading, Populated, StoreRatingsTab}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Profile loading
    msg.LoadProfile -> {
      let new_model = Model(..model, profile: Loading)
      #(new_model, effects.fetch_user_profile())
    }

    msg.ProfileLoaded(profile) -> {
      let new_model = Model(..model, profile: Populated(profile))
      // After profile loads, fetch initial ratings for active tab
      let effect = case model.active_tab {
        StoreRatingsTab -> effects.fetch_store_ratings(1, model.per_page)
        DrinkRatingsTab -> effects.fetch_drink_ratings(1, model.per_page)
      }
      #(new_model, effect)
    }

    msg.ProfileLoadFailed(error) -> {
      let new_model = Model(..model, profile: Error(error))
      #(new_model, effect.none())
    }

    // Tab switching
    msg.SwitchTab(tab) -> {
      let new_model = Model(..model, active_tab: tab, current_page: 1)
      // Fetch ratings for the new tab if not already loaded
      let effect = case tab {
        StoreRatingsTab -> {
          case model.store_ratings {
            Loading -> effects.fetch_store_ratings(1, model.per_page)
            Empty -> effects.fetch_store_ratings(1, model.per_page)
            Error(_) -> effects.fetch_store_ratings(1, model.per_page)
            Populated(_) -> effect.none()
          }
        }
        DrinkRatingsTab -> {
          case model.drink_ratings {
            Loading -> effects.fetch_drink_ratings(1, model.per_page)
            Empty -> effects.fetch_drink_ratings(1, model.per_page)
            Error(_) -> effects.fetch_drink_ratings(1, model.per_page)
            Populated(_) -> effect.none()
          }
        }
      }
      #(new_model, effect)
    }

    // Store ratings
    msg.LoadStoreRatings(page) -> {
      let new_model = Model(..model, current_page: page, store_ratings: Loading)
      #(new_model, effects.fetch_store_ratings(page, model.per_page))
    }

    msg.StoreRatingsLoaded(items, total) -> {
      let new_model = case items {
        [] -> Model(..model, store_ratings: Empty, store_ratings_total: total)
        _ -> Model(..model, store_ratings: Populated(items), store_ratings_total: total)
      }
      #(new_model, effect.none())
    }

    msg.StoreRatingsLoadFailed(error) -> {
      let new_model = Model(..model, store_ratings: Error(error))
      #(new_model, effect.none())
    }

    // Drink ratings
    msg.LoadDrinkRatings(page) -> {
      let new_model = Model(..model, current_page: page, drink_ratings: Loading)
      #(new_model, effects.fetch_drink_ratings(page, model.per_page))
    }

    msg.DrinkRatingsLoaded(items, total) -> {
      let new_model = case items {
        [] -> Model(..model, drink_ratings: Empty, drink_ratings_total: total)
        _ -> Model(..model, drink_ratings: Populated(items), drink_ratings_total: total)
      }
      #(new_model, effect.none())
    }

    msg.DrinkRatingsLoadFailed(error) -> {
      let new_model = Model(..model, drink_ratings: Error(error))
      #(new_model, effect.none())
    }

    // Pagination
    msg.ChangePage(page) -> {
      let new_model = Model(..model, current_page: page)
      let effect = case model.active_tab {
        StoreRatingsTab -> effects.fetch_store_ratings(page, model.per_page)
        DrinkRatingsTab -> effects.fetch_drink_ratings(page, model.per_page)
      }
      #(new_model, effect)
    }
  }
}
