import auth/crypto
import gleam/dynamic/decode
import gleam/json
import gleam/result
import gleam/string

const token_ttl_seconds = 86_400

pub fn create(user_id: String, secret: String) -> String {
  let exp = crypto.system_time_seconds() + token_ttl_seconds
  let payload =
    json.object([#("sub", json.string(user_id)), #("exp", json.int(exp))])
    |> json.to_string
  let signature = crypto.hmac_sign(payload, secret)
  payload <> "." <> signature
}

pub fn verify(token: String, secret: String) -> Result(String, String) {
  case string.split(token, ".") {
    [payload, signature] -> {
      let expected = crypto.hmac_sign(payload, secret)
      case signature == expected {
        False -> Error("Invalid token signature")
        True -> decode_and_validate(payload)
      }
    }
    _ -> Error("Invalid token format")
  }
}

fn decode_and_validate(payload: String) -> Result(String, String) {
  let decoder = {
    use sub <- decode.field("sub", decode.string)
    use exp <- decode.field("exp", decode.int)
    decode.success(#(sub, exp))
  }
  use decoded <- result.try(
    json.parse(from: payload, using: decoder)
    |> result.map_error(fn(_) { "Invalid token payload" }),
  )
  let #(sub, exp) = decoded
  case crypto.system_time_seconds() < exp {
    True -> Ok(sub)
    False -> Error("Token expired")
  }
}
