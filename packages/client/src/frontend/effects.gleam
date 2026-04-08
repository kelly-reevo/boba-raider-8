import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/int
import gleam/json
import frontend/model.{AuthUser}
import frontend/msg.{type Msg}
import lustre/effect.{type Effect}
import shared.{type RatingSubmission}

@external(javascript, "./auth_ffi.mjs", "get_saved_token")
fn do_get_saved_token() -> String

@external(javascript, "./auth_ffi.mjs", "save_token")
fn do_save_token(token: String) -> Nil

@external(javascript, "./auth_ffi.mjs", "clear_token")
fn do_clear_token() -> Nil

@external(javascript, "./auth_ffi.mjs", "do_login")
fn ffi_login(
  email: String,
  password: String,
  on_ok: fn(String, String, String, String) -> Nil,
  on_err: fn(String) -> Nil,
) -> Nil

@external(javascript, "./auth_ffi.mjs", "do_register")
fn ffi_register(
  username: String,
  email: String,
  password: String,
  on_ok: fn(String, String, String, String) -> Nil,
  on_err: fn(String) -> Nil,
) -> Nil

@external(javascript, "./auth_ffi.mjs", "do_fetch_profile")
fn ffi_fetch_profile(
  token: String,
  on_ok: fn(String, String, String) -> Nil,
  on_err: fn(String) -> Nil,
) -> Nil

@external(javascript, "./effects_ffi.mjs", "do_fetch")
fn do_fetch(
  url: String,
  on_ok: fn(Dynamic) -> Nil,
  on_err: fn(String) -> Nil,
) -> Nil

@external(javascript, "../rating_ffi.mjs", "submitRating")
fn do_submit_rating(body: String, callback: fn(Int) -> Nil) -> Nil

pub fn check_saved_token() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let token = do_get_saved_token()
    case token {
      "" -> Nil
      t -> dispatch(msg.GotSavedToken(t))
    }
  })
}

pub fn save_token(token: String) -> Effect(Msg) {
  effect.from(fn(_dispatch) { do_save_token(token) })
}

pub fn clear_token() -> Effect(Msg) {
  effect.from(fn(_dispatch) { do_clear_token() })
}

pub fn login(email: String, password: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    ffi_login(
      email,
      password,
      fn(token, id, username, user_email) {
        let user = AuthUser(id: id, username: username, email: user_email)
        let resp = msg.AuthResult(token: token, user: user)
        dispatch(msg.GotAuth(Ok(resp)))
      },
      fn(err) { dispatch(msg.GotAuth(Error(err))) },
    )
  })
}

pub fn register(
  username: String,
  email: String,
  password: String,
) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    ffi_register(
      username,
      email,
      password,
      fn(token, id, resp_username, user_email) {
        let user =
          AuthUser(id: id, username: resp_username, email: user_email)
        let resp = msg.AuthResult(token: token, user: user)
        dispatch(msg.GotAuth(Ok(resp)))
      },
      fn(err) { dispatch(msg.GotAuth(Error(err))) },
    )
  })
}

pub fn fetch_profile(token: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    ffi_fetch_profile(
      token,
      fn(id, username, email) {
        let user = AuthUser(id: id, username: username, email: email)
        dispatch(msg.GotProfile(Ok(user)))
      },
      fn(err) { dispatch(msg.GotProfile(Error(err))) },
    )
  })
}

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

fn fetch_json(
  url: String,
  decoder: decode.Decoder(a),
  to_msg: fn(Result(a, String)) -> msg.Msg,
) -> Effect(msg.Msg) {
  effect.from(fn(dispatch) {
    do_fetch(
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

pub fn submit_rating(rating: RatingSubmission) -> Effect(msg.Msg) {
  let body =
    json.object([
      #("sweetness", json.int(rating.sweetness)),
      #("boba_texture", json.int(rating.boba_texture)),
      #("tea_strength", json.int(rating.tea_strength)),
      #("overall", json.int(rating.overall)),
    ])
    |> json.to_string

  effect.from(fn(dispatch) {
    do_submit_rating(body, fn(status) {
      case status >= 200 && status < 300 {
        True -> dispatch(msg.RatingSubmitted(Ok(Nil)))
        False ->
          dispatch(
            msg.RatingSubmitted(Error(
              "Submission failed (status " <> int.to_string(status) <> ")",
            )),
          )
      }
    })
  })
}
