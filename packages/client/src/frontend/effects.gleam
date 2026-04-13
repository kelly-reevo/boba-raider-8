import frontend/msg.{type Msg}
import lustre/effect.{type Effect}

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
