/// Store List Update - State transitions and effects for the store list page

import frontend/store_list/model.{
  type Model, type Pagination, type SortBy, type Store,
  Loaded, Loading, Error as LoadingError, Idle,
  SortByName, SortByCity, Asc, Desc,
}
import frontend/store_list/msg.{type Msg}
import lustre/effect.{type Effect}
import gleam/int
import gleam/list

/// Debounce delay in milliseconds for search
const debounce_delay = 300

/// Handle state updates
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Search input changed - update immediately but debounce the API call
    msg.SearchInputChanged(new_term) -> {
      let updated_model = model.Model(..model, search_term: new_term, pending_search_timer: debounce_delay)
      #(updated_model, start_debounce_timer())
    }

    // Timer ticked - countdown the debounce
    msg.SearchTimerTicked -> {
      case model.pending_search_timer > 0 {
        True -> {
          let updated_model = model.Model(..model, pending_search_timer: model.pending_search_timer - 50)
          #(updated_model, continue_timer())
        }
        False -> {
          case model.debounced_search != model.search_term {
            True -> {
              let updated_model = model.Model(
                ..model,
                debounced_search: model.search_term,
                pagination: model.Pagination(..model.pagination, offset: 0),
              )
              #(updated_model, fetch_stores(updated_model))
            }
            False -> #(model, effect.none())
          }
        }
      }
    }

    // Debounced search triggered manually
    msg.DebouncedSearchTriggered -> {
      let updated_model = model.Model(
        ..model,
        debounced_search: model.search_term,
        pagination: model.Pagination(..model.pagination, offset: 0),
      )
      #(updated_model, fetch_stores(updated_model))
    }

    // Page number clicked
    msg.PageChanged(page_num) -> {
      let new_offset = { page_num - 1 } * model.pagination.limit
      let updated_model = model.Model(
        ..model,
        pagination: model.Pagination(..model.pagination, offset: new_offset),
      )
      #(updated_model, fetch_stores(updated_model))
    }

    // Next page button clicked
    msg.NextPage -> {
      case has_next_page(model.pagination) {
        True -> {
          let new_offset = model.pagination.offset + model.pagination.limit
          let updated_model = model.Model(
            ..model,
            pagination: model.Pagination(..model.pagination, offset: new_offset),
          )
          #(updated_model, fetch_stores(updated_model))
        }
        False -> #(model, effect.none())
      }
    }

    // Previous page button clicked
    msg.PrevPage -> {
      case has_prev_page(model.pagination) {
        True -> {
          let new_offset = model.pagination.offset - model.pagination.limit
          let new_offset = case new_offset < 0 {
            True -> 0
            False -> new_offset
          }
          let updated_model = model.Model(
            ..model,
            pagination: model.Pagination(..model.pagination, offset: new_offset),
          )
          #(updated_model, fetch_stores(updated_model))
        }
        False -> #(model, effect.none())
      }
    }

    // Sort by changed
    msg.SortByChanged(new_sort_by) -> {
      let updated_model = model.Model(
        ..model,
        sort_by: new_sort_by,
        pagination: model.Pagination(..model.pagination, offset: 0),
      )
      #(updated_model, fetch_stores(updated_model))
    }

    // Sort order changed
    msg.SortOrderChanged(new_sort_order) -> {
      let updated_model = model.Model(
        ..model,
        sort_order: new_sort_order,
        pagination: model.Pagination(..model.pagination, offset: 0),
      )
      #(updated_model, fetch_stores(updated_model))
    }

    // Stores successfully loaded from API
    msg.StoresLoaded(stores, total) -> {
      let updated_model = model.Model(
        ..model,
        stores: stores,
        pagination: model.Pagination(..model.pagination, total: total),
        loading_state: Loaded,
      )
      #(updated_model, effect.none())
    }

    // Failed to load stores
    msg.StoresLoadFailed(error) -> {
      let updated_model = model.Model(..model, loading_state: LoadingError(error))
      #(updated_model, effect.none())
    }
  }
}

/// Start the debounce timer
fn start_debounce_timer() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // Simulate timer by dispatching tick immediately
    dispatch(msg.SearchTimerTicked)
    Nil
  })
}

/// Continue the timer ticking
fn continue_timer() -> Effect(Msg) {
  // In a real implementation, this would use a proper timer effect
  // For simplicity, we'll just dispatch immediately
  effect.from(fn(dispatch) {
    dispatch(msg.SearchTimerTicked)
    Nil
  })
}

/// Fetch stores from API
fn fetch_stores(model: Model) -> Effect(Msg) {
  // Build query parameters
  let limit = int.to_string(model.pagination.limit)
  let offset = int.to_string(model.pagination.offset)
  let search = model.debounced_search
  let sort_by = case model.sort_by {
    SortByName -> "name"
    SortByCity -> "city"
  }
  let sort_order = case model.sort_order {
    Asc -> "asc"
    Desc -> "desc"
  }

  // Build URL
  let base_url = "/api/stores"
  let query_params = "?limit=" <> limit
    <> "&offset=" <> offset
    <> "&search=" <> search
    <> "&sort_by=" <> sort_by
    <> "&sort_order=" <> sort_order

  let url = base_url <> query_params

  // Create HTTP effect
  effect.from(fn(dispatch) {
    do_fetch(url, dispatch)
    Nil
  })
}

/// Perform the actual HTTP fetch
fn do_fetch(url: String, dispatch: fn(Msg) -> Nil) -> Nil {
  // This uses JavaScript interop for fetch API
  fetch_stores_js(url, fn(result) {
    case result {
      Ok(tuple) -> {
        let #(stores, total) = tuple
        dispatch(msg.StoresLoaded(stores, total))
      }
      Error(err_msg) -> dispatch(msg.StoresLoadFailed(err_msg))
    }
  })
}

/// JavaScript FFI for fetch
@external(javascript, "./store_list_ffi.mjs", "fetchStores")
fn fetch_stores_js(
  url: String,
  callback: fn(Result(#(List(Store), Int), String)) -> Nil,
) -> Nil

// Helper functions for pagination
fn has_next_page(pagination: Pagination) -> Bool {
  let total_pages = { pagination.total + pagination.limit - 1 } / pagination.limit
  let current_page_num = pagination.offset / pagination.limit + 1
  current_page_num < total_pages && pagination.total > 0
}

fn has_prev_page(pagination: Pagination) -> Bool {
  pagination.offset > 0
}
