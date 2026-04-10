/// Application update logic

import gleam/list
import frontend/model.{
  type Model, type StoreListState, type RemoteData, Model, StoreListState,
  NotAsked, Loading, Success, Failure,
}
import frontend/msg.{type Msg, type StoreListMsg, Counter, StoreList, LoadStores, StoresLoaded, SearchChanged, LocationChanged, SortChanged, PageChanged, RetryLoad}
import frontend/effects
import lustre/effect.{type Effect}
import shared.{type Store, type StoreFilters, type SortOption}

/// Main update function
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    Counter(counter_msg) -> update_counter(model, counter_msg)
    StoreList(store_msg) -> update_store_list(model, store_msg)
  }
}

/// Handle counter messages (legacy)
fn update_counter(model: Model, msg) -> #(Model, Effect(Msg)) {
  case msg {
    msg.Increment -> #(Model(..model, count: model.count + 1), effect.none())
    msg.Decrement -> #(Model(..model, count: model.count - 1), effect.none())
    msg.Reset -> #(Model(..model, count: 0), effect.none())
  }
}

/// Handle store list messages
fn update_store_list(model: Model, msg: StoreListMsg) -> #(Model, Effect(Msg)) {
  let state = model.store_list

  case msg {
    LoadStores -> {
      let new_state = StoreListState(..state, stores: Loading)
      let new_model = Model(..model, store_list: new_state)
      #(new_model, effects.fetch_stores(state.filters))
    }

    StoresLoaded(result) -> {
      let new_state = case result {
        Ok(stores) -> StoreListState(..state, stores: Success(stores), has_more: list.length(stores) >= 20)
        Error(err) -> StoreListState(..state, stores: Failure(err))
      }
      #(Model(..model, store_list: new_state), effect.none())
    }

    SearchChanged(query) -> {
      let new_filters = shared.StoreFilters(..state.filters, query: query, page: 1)
      let new_state = StoreListState(..state, filters: new_filters, stores: Loading)
      #(Model(..model, store_list: new_state), effects.fetch_stores(new_filters))
    }

    LocationChanged(location) -> {
      let new_filters = shared.StoreFilters(..state.filters, location: location, page: 1)
      let new_state = StoreListState(..state, filters: new_filters, stores: Loading)
      #(Model(..model, store_list: new_state), effects.fetch_stores(new_filters))
    }

    SortChanged(sort) -> {
      let new_filters = shared.StoreFilters(..state.filters, sort: sort, page: 1)
      let new_state = StoreListState(..state, filters: new_filters, stores: Loading)
      #(Model(..model, store_list: new_state), effects.fetch_stores(new_filters))
    }

    PageChanged(page) -> {
      let new_filters = shared.StoreFilters(..state.filters, page: page)
      let new_state = StoreListState(..state, filters: new_filters, stores: Loading)
      #(Model(..model, store_list: new_state), effects.fetch_stores(new_filters))
    }

    RetryLoad -> {
      let new_state = StoreListState(..state, stores: Loading)
      #(Model(..model, store_list: new_state), effects.fetch_stores(state.filters))
    }
  }
}
