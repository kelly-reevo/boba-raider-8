import gleam/json
import gleam/dict.{type Dict}
import gleam/result
import gleam/string
import gleam/erlang/process.{type Subject}
import gleam/otp/actor

/// Token storage actor state
pub type TokenStore {
  TokenStore(refresh_tokens: Dict(String, RefreshTokenData))
}

pub type RefreshTokenData {
  RefreshTokenData(user_id: String, created_at: Int)
}

/// Public API types
pub type TokenPair {
  TokenPair(access_token: String, refresh_token: String)
}

pub type AuthError {
  InvalidToken
  ExpiredToken
  TokenNotFound
}

/// Messages for the token store actor
pub type TokenStoreMsg {
  ValidateRefreshToken(String, Subject(Result(TokenPair, AuthError)))
  StoreRefreshToken(String, RefreshTokenData)
  RemoveRefreshToken(String)
}

/// Generate a new token pair - called when refresh is successful
fn generate_token_pair(user_id: String) -> TokenPair {
  // Simple token generation - in production, use proper JWT or signed tokens
  let timestamp = generate_timestamp()
  let access_token = "access_" <> user_id <> "_" <> timestamp
  let refresh_token = "refresh_" <> user_id <> "_" <> timestamp <> "_random"
  TokenPair(access_token:, refresh_token:)
}

@external(erlang, "erlang", "system_time")
fn system_time(unit: Int) -> Int

fn generate_timestamp() -> String {
  // 1000 = millisecond unit for erlang:system_time
  system_time(1000) |> int_to_string()
}

fn int_to_string(n: Int) -> String {
  case n {
    0 -> "0"
    _ -> do_int_to_string(n, "")
  }
}

fn do_int_to_string(n: Int, acc: String) -> String {
  case n {
    0 -> acc
    _ -> do_int_to_string(n / 10, int_to_digit(n % 10) <> acc)
  }
}

fn int_to_digit(n: Int) -> String {
  case n {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    6 -> "6"
    7 -> "7"
    8 -> "8"
    9 -> "9"
    _ -> "0"
  }
}

/// Start the token store actor
pub fn start_token_store() -> Result(Subject(TokenStoreMsg), String) {
  let initial_state = TokenStore(dict.new())

  actor.new(initial_state)
  |> actor.on_message(fn(state, msg) {
    case msg {
      ValidateRefreshToken(token, reply_to) -> {
        let result = case dict.get(state.refresh_tokens, token) {
          Ok(data) -> {
            // Token exists - generate new pair and invalidate old refresh token
            let new_pair = generate_token_pair(data.user_id)
            let new_data = RefreshTokenData(
              user_id: data.user_id,
              created_at: generate_timestamp() |> parse_int_or_zero(),
            )
            let new_tokens = state.refresh_tokens
              |> dict.delete(token)
              |> dict.insert(new_pair.refresh_token, new_data)

            actor.send(reply_to, Ok(new_pair))
            actor.continue(TokenStore(new_tokens))
          }
          Error(_) -> {
            actor.send(reply_to, Error(InvalidToken))
            actor.continue(state)
          }
        }
        result
      }

      StoreRefreshToken(token, data) -> {
        let new_tokens = dict.insert(state.refresh_tokens, token, data)
        actor.continue(TokenStore(new_tokens))
      }

      RemoveRefreshToken(token) -> {
        let new_tokens = dict.delete(state.refresh_tokens, token)
        actor.continue(TokenStore(new_tokens))
      }
    }
  })
  |> actor.start()
  |> result.map(fn(started) { started.data })
  |> result.map_error(fn(_) { "Failed to start token store" })
}

fn parse_int_or_zero(s: String) -> Int {
  parse_int(s, 0)
}

fn parse_int(s: String, default: Int) -> Int {
  do_parse_int(s, default, 0)
}

fn do_parse_int(s: String, default: Int, acc: Int) -> Int {
  case string.pop_grapheme(s) {
    Ok(#(c, rest)) -> {
      case c {
        "0" -> do_parse_int(rest, default, acc * 10 + 0)
        "1" -> do_parse_int(rest, default, acc * 10 + 1)
        "2" -> do_parse_int(rest, default, acc * 10 + 2)
        "3" -> do_parse_int(rest, default, acc * 10 + 3)
        "4" -> do_parse_int(rest, default, acc * 10 + 4)
        "5" -> do_parse_int(rest, default, acc * 10 + 5)
        "6" -> do_parse_int(rest, default, acc * 10 + 6)
        "7" -> do_parse_int(rest, default, acc * 10 + 7)
        "8" -> do_parse_int(rest, default, acc * 10 + 8)
        "9" -> do_parse_int(rest, default, acc * 10 + 9)
        _ -> default
      }
    }
    Error(_) -> acc
  }
}

/// Refresh token - validates and issues new token pair
pub fn refresh_token(
  store: Subject(TokenStoreMsg),
  refresh_token: String,
) -> Result(TokenPair, AuthError) {
  let reply_subject = process.new_subject()
  actor.send(store, ValidateRefreshToken(refresh_token, reply_subject))

  // Wait for response with timeout
  case process.receive(reply_subject, 5000) {
    Ok(result) -> result
    Error(_) -> Error(TokenNotFound)
  }
}

/// Convert AuthError to JSON error response
pub fn error_to_json(error: AuthError) -> String {
  let message = case error {
    InvalidToken -> "Invalid or malformed token"
    ExpiredToken -> "Token has expired"
    TokenNotFound -> "Token not found"
  }

  json.object([#("error", json.string(message))])
  |> json.to_string()
}

/// Convert TokenPair to JSON response
pub fn tokens_to_json(pair: TokenPair) -> String {
  json.object([
    #("access_token", json.string(pair.access_token)),
    #("refresh_token", json.string(pair.refresh_token)),
  ])
  |> json.to_string()
}
