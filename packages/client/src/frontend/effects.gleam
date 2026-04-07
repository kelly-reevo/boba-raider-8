import frontend/msg.{type Msg}
import lustre/effect.{type Effect}
import shared

@external(javascript, "../ratings_ffi.mjs", "fetchRatings")
fn fetch_ratings_http(
  on_success: fn(String) -> Nil,
  on_error: fn(String) -> Nil,
) -> Nil

pub fn fetch_ratings_effect() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    fetch_ratings_http(
      fn(json_string) {
        case shared.decode_ratings_summary(json_string) {
          Ok(summary) -> dispatch(msg.RatingsLoaded(summary))
          Error(_) ->
            dispatch(msg.RatingsFetchError("Invalid response format"))
        }
      },
      fn(error_msg) { dispatch(msg.RatingsFetchError(error_msg)) },
    )
  })
}
