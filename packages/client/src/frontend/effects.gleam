import frontend/msg
import gleam/int
import gleam/json
import lustre/effect.{type Effect}
import shared.{type RatingSubmission}

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

@external(javascript, "../rating_ffi.mjs", "submitRating")
fn do_submit_rating(body: String, callback: fn(Int) -> Nil) -> Nil
