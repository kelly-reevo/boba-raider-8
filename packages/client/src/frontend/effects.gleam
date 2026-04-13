import frontend/msg.{type Msg}
import gleam/dynamic/decode
import gleam/fetch
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/javascript/promise
import gleam/json
import lustre/effect.{type Effect}

@external(javascript, "./origin_ffi.mjs", "get_origin")
fn get_origin() -> String

fn count_decoder() -> decode.Decoder(Int) {
  use count <- decode.field("count", decode.int)
  decode.success(count)
}

fn api_get(path: String, to_msg: fn(Result(Int, msg.HttpError)) -> Msg) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let assert Ok(req) = request.to(get_origin() <> path)
    fetch.send(req)
    |> promise.try_await(fetch.read_text_body)
    |> promise.map(fn(result) {
      case result {
        Ok(resp) -> decode_counter_response(resp, to_msg)
        Error(_) -> to_msg(Error(msg.NetworkError))
      }
    })
    |> promise.tap(dispatch)
    Nil
  })
}

fn api_post(path: String, to_msg: fn(Result(Int, msg.HttpError)) -> Msg) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let assert Ok(req) = request.to(get_origin() <> path)
    let req =
      req
      |> request.set_method(http.Post)
      |> request.set_header("content-type", "application/json")
      |> request.set_body(json.to_string(json.null()))
    fetch.send(req)
    |> promise.try_await(fetch.read_text_body)
    |> promise.map(fn(result) {
      case result {
        Ok(resp) -> decode_counter_response(resp, to_msg)
        Error(_) -> to_msg(Error(msg.NetworkError))
      }
    })
    |> promise.tap(dispatch)
    Nil
  })
}

fn decode_counter_response(
  resp: response.Response(String),
  to_msg: fn(Result(Int, msg.HttpError)) -> Msg,
) -> Msg {
  case resp.status {
    status if status >= 200 && status <= 299 ->
      case json.parse(resp.body, count_decoder()) {
        Ok(count) -> to_msg(Ok(count))
        Error(_) -> to_msg(Error(msg.DecodeError))
      }
    status -> to_msg(Error(msg.ServerError(status)))
  }
}

pub fn fetch_counter() -> Effect(Msg) {
  api_get("/api/counter", msg.GotCounter)
}

pub fn post_increment() -> Effect(Msg) {
  api_post("/api/counter/increment", msg.GotCounter)
}

pub fn post_decrement() -> Effect(Msg) {
  api_post("/api/counter/decrement", msg.GotCounter)
}

pub fn post_reset() -> Effect(Msg) {
  api_post("/api/counter/reset", msg.GotCounter)
}
