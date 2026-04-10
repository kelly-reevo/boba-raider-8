import gleam/bit_array
import gleam/dynamic/decode
import gleam/json
import gleam/string

/// JWT token generation and verification
pub type JwtError {
  InvalidToken
  ExpiredToken
  InvalidSignature
  DecodeError(String)
}

/// Generate JWT tokens for authenticated user
pub fn generate_tokens(
  user_id: String,
  email: String,
  username: String,
  secret: String,
) -> Result(#(String, String), JwtError) {
  let access_token = generate_access_token(user_id, email, username, secret)
  let refresh_token = generate_refresh_token(user_id, secret)
  Ok(#(access_token, refresh_token))
}

/// Generate short-lived access token (15 minutes)
fn generate_access_token(
  user_id: String,
  email: String,
  username: String,
  secret: String,
) -> String {
  let header_json =
    json.object([#("alg", json.string("HS256")), #("typ", json.string("JWT"))])

  let now = current_timestamp()
  let exp = now + 900

  let payload_json =
    json.object([
      #("sub", json.string(user_id)),
      #("email", json.string(email)),
      #("username", json.string(username)),
      #("iat", json.int(now)),
      #("exp", json.int(exp)),
      #("type", json.string("access")),
    ])

  let header = base64_url_encode_string(json.to_string(header_json))
  let payload = base64_url_encode_string(json.to_string(payload_json))
  let signing_input = header <> "." <> payload

  let signature = hmac_sha256(signing_input, secret)
  let signature_b64 = base64_url_encode_bitarray(signature)

  signing_input <> "." <> signature_b64
}

/// Generate long-lived refresh token (7 days)
fn generate_refresh_token(user_id: String, secret: String) -> String {
  let header_json =
    json.object([#("alg", json.string("HS256")), #("typ", json.string("JWT"))])

  let now = current_timestamp()
  let exp = now + 604_800

  let payload_json =
    json.object([
      #("sub", json.string(user_id)),
      #("iat", json.int(now)),
      #("exp", json.int(exp)),
      #("type", json.string("refresh")),
    ])

  let header = base64_url_encode_string(json.to_string(header_json))
  let payload = base64_url_encode_string(json.to_string(payload_json))
  let signing_input = header <> "." <> payload

  let signature = hmac_sha256(signing_input, secret)
  let signature_b64 = base64_url_encode_bitarray(signature)

  signing_input <> "." <> signature_b64
}

/// Verify and decode access token, return user info
pub fn verify_access_token(
  token: String,
  secret: String,
) -> Result(#(String, String, String), JwtError) {
  case string.split(token, ".") {
    [header, payload, signature] -> {
      let signing_input = header <> "." <> payload

      let expected_sig = hmac_sha256(signing_input, secret)
      let expected_sig_b64 = base64_url_encode_bitarray(expected_sig)

      case signature == expected_sig_b64 {
        True -> {
          let decoded_payload = base64_url_decode_string(payload)
          case decode_access_payload(decoded_payload) {
            Ok(#(user_id, email, username, exp)) -> {
              let now = current_timestamp()
              case exp > now {
                True -> Ok(#(user_id, email, username))
                False -> Error(ExpiredToken)
              }
            }
            Error(_) -> Error(DecodeError("Invalid payload"))
          }
        }
        False -> Error(InvalidSignature)
      }
    }
    _ -> Error(InvalidToken)
  }
}

/// Decoder for JWT payload
fn access_payload_decoder() {
  use sub <- decode.field("sub", decode.string)
  use email <- decode.field("email", decode.string)
  use username <- decode.field("username", decode.string)
  use exp <- decode.field("exp", decode.int)
  decode.success(#(sub, email, username, exp))
}

/// Decode access token payload
fn decode_access_payload(
  payload: String,
) -> Result(#(String, String, String, Int), Nil) {
  case json.parse(payload, access_payload_decoder()) {
    Ok(data) -> Ok(data)
    Error(_) -> Error(Nil)
  }
}

/// URL-safe base64 encode for strings
fn base64_url_encode_string(data: String) -> String {
  bit_array.from_string(data)
  |> bit_array.base64_url_encode(False)
}

/// URL-safe base64 encode for bit arrays
fn base64_url_encode_bitarray(data: BitArray) -> String {
  bit_array.base64_url_encode(data, False)
}

/// URL-safe base64 decode to string
fn base64_url_decode_string(data: String) -> String {
  case bit_array.base64_url_decode(data) {
    Ok(bits) -> {
      case bit_array.to_string(bits) {
        Ok(str) -> str
        Error(_) -> ""
      }
    }
    Error(_) -> ""
  }
}

/// Get current timestamp in seconds
fn current_timestamp() -> Int {
  erlang_system_time()
}

// FFI functions
@external(erlang, "jwt_ffi", "hmac_sha256")
fn hmac_sha256(data: String, key: String) -> BitArray

@external(erlang, "jwt_ffi", "system_time")
fn erlang_system_time() -> Int
