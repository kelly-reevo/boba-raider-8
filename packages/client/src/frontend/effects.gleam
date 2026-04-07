/// API effects for store detail

import frontend/msg
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import lustre/effect.{type Effect}
import shared

@external(javascript, "../fetch_ffi.mjs", "get_json")
fn get_json(
  url: String,
  on_success: fn(Dynamic) -> Nil,
  on_error: fn(String) -> Nil,
) -> Nil

fn fetch_json(
  url: String,
  decoder: decode.Decoder(a),
  to_msg: fn(Result(a, String)) -> msg.Msg,
) -> Effect(msg.Msg) {
  effect.from(fn(dispatch) {
    get_json(
      url,
      fn(data) {
        case decode.run(data, decoder) {
          Ok(value) -> dispatch(to_msg(Ok(value)))
          Error(_) -> dispatch(to_msg(Error("Failed to parse response")))
        }
      },
      fn(err) { dispatch(to_msg(Error(err))) },
    )
  })
}

pub fn fetch_store(store_id: String) -> Effect(msg.Msg) {
  fetch_json(
    "/api/stores/" <> store_id,
    shared.store_decoder(),
    msg.GotStore,
  )
}

pub fn fetch_drinks(store_id: String) -> Effect(msg.Msg) {
  fetch_json(
    "/api/stores/" <> store_id <> "/drinks",
    shared.drinks_decoder(),
    msg.GotDrinks,
  )
}

pub fn fetch_store_detail(store_id: String) -> Effect(msg.Msg) {
  effect.batch([fetch_store(store_id), fetch_drinks(store_id)])
}
