/// Effects for API calls and side effects

import frontend/model.{type DrinkCard, type StoreInfo, DrinkCard, StoreInfo}
import frontend/msg.{type Msg}
import gleam/dynamic/decode.{type Decoder}
import lustre/effect.{type Effect}

/// Fetch store details and drinks on page load
pub fn fetch_store_data(store_id: String) -> Effect(Msg) {
  effect.batch([
    fetch_store_details(store_id),
    fetch_store_drinks(store_id),
  ])
}

/// Fetch store details from GET /api/stores/:id
fn fetch_store_details(store_id: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // In a real app, this would dispatch the HTTP request
    // For now, we simulate the structure
    dispatch(msg.StoreLoaded(StoreInfo(
      id: store_id,
      name: "",  // Will be populated by actual API
      location: "",
    )))
  })
}

/// Fetch drinks from GET /api/stores/:id/drinks
fn fetch_store_drinks(store_id: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // In a real app with proper HTTP client, we would:
    // 1. Send the request
    // 2. Decode JSON response using drink_response_decoder
    // 3. Dispatch DrinksLoaded or DrinksLoadFailed

    // For now, simulate empty list (will be populated by actual API)
    dispatch(msg.DrinksLoaded([]))
  })
}

/// Decoder for the aggregates sub-object: {overall_rating: float}
fn aggregates_decoder() -> Decoder(Float) {
  use overall_rating <- decode.field("overall_rating", decode.float)
  decode.success(overall_rating)
}

/// Decoder for DrinkCard from API response
/// Handles JSON shape: {id, name, base_tea_type, price, aggregates: {overall_rating}}
fn drink_card_decoder() -> Decoder(DrinkCard) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use base_tea_type <- decode.field("base_tea_type", decode.string)
  use price <- decode.field("price", decode.float)
  use overall_rating <- decode.field("aggregates", aggregates_decoder())

  decode.success(DrinkCard(
    id: id,
    name: name,
    base_tea_type: base_tea_type,
    price: price,
    overall_rating: overall_rating,
  ))
}

/// Decoder for drinks list response {drinks: [...]}
fn drinks_response_decoder() -> Decoder(List(DrinkCard)) {
  use drinks <- decode.field("drinks", decode.list(drink_card_decoder()))
  decode.success(drinks)
}

/// Decoder for store info from GET /api/stores/:id
fn store_info_decoder() -> Decoder(StoreInfo) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)

  // Location may be constructed from address + city fields
  decode.success(StoreInfo(
    id: id,
    name: name,
    location: "",  // Can be extended to decode address/city
  ))
}

/// Submit create drink form via FFI to JavaScript fetch
pub fn submit_create_drink(
  store_id: String,
  name: String,
  description: String,
  base_tea_type: String,
  price: String,
) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // Use FFI to call JavaScript fetch
    do_submit_create_drink(store_id, name, description, base_tea_type, price, dispatch)
  })
}

@external(javascript, "../ffi/create_drink_form_ffi.mjs", "submitCreateDrink")
fn do_submit_create_drink(
  store_id: String,
  name: String,
  description: String,
  base_tea_type: String,
  price: String,
  dispatch: fn(Msg) -> Nil,
) -> Nil
