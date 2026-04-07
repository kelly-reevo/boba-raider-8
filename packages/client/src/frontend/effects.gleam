import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import frontend/msg.{type Msg}
import lustre/effect.{type Effect}
import shared

@external(javascript, "./effects_ffi.mjs", "do_fetch")
fn do_fetch(
  url: String,
  on_ok: fn(Dynamic) -> Nil,
  on_err: fn(String) -> Nil,
) -> Nil

pub fn fetch_stores() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    do_fetch("/api/stores", fn(json_data) {
      case decode.run(json_data, shared.stores_response_decoder()) {
        Ok(stores) -> dispatch(msg.ApiReturnedStores(Ok(stores)))
        Error(_) ->
          dispatch(msg.ApiReturnedStores(Error("Failed to parse response")))
      }
    }, fn(error_message) {
      dispatch(msg.ApiReturnedStores(Error(error_message)))
    })
  })
}
