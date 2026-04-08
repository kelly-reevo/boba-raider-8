import auth/token
import auth/user_store.{type StoredUser, type UserStore}
import gleam/dict
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/json
import gleam/result
import gleam/string
import web/server.{type Request, type Response}

pub fn handle_register(
  request: Request,
  store: UserStore,
  secret: String,
) -> Response {
  case decode_register_body(request.body) {
    Error(_) -> error_response(400, "Invalid request body")
    Ok(#(email, name, password)) -> {
      case
        process.call(
          store,
          5000,
          fn(reply) { user_store.Register(email, name, password, reply) },
        )
      {
        Ok(user) -> auth_success_response(user, secret)
        Error(msg) -> error_response(409, msg)
      }
    }
  }
}

pub fn handle_login(
  request: Request,
  store: UserStore,
  secret: String,
) -> Response {
  case decode_login_body(request.body) {
    Error(_) -> error_response(400, "Invalid request body")
    Ok(#(email, password)) -> {
      case
        process.call(
          store,
          5000,
          fn(reply) { user_store.Authenticate(email, password, reply) },
        )
      {
        Ok(user) -> auth_success_response(user, secret)
        Error(msg) -> error_response(401, msg)
      }
    }
  }
}

pub fn handle_me(
  request: Request,
  store: UserStore,
  secret: String,
) -> Response {
  case extract_token(request) {
    Error(msg) -> error_response(401, msg)
    Ok(tok) -> {
      case token.verify(tok, secret) {
        Error(msg) -> error_response(401, msg)
        Ok(user_id) -> {
          case
            process.call(
              store,
              5000,
              fn(reply) { user_store.GetById(user_id, reply) },
            )
          {
            Ok(user) -> user_response(user)
            Error(msg) -> error_response(404, msg)
          }
        }
      }
    }
  }
}

fn extract_token(request: Request) -> Result(String, String) {
  case dict.get(request.headers, "authorization") {
    Error(Nil) -> Error("Missing authorization header")
    Ok(value) -> {
      case string.starts_with(value, "Bearer ") {
        True -> Ok(string.drop_start(value, 7))
        False -> Error("Invalid authorization header format")
      }
    }
  }
}

fn decode_register_body(
  body: String,
) -> Result(#(String, String, String), Nil) {
  let decoder = {
    use email <- decode.field("email", decode.string)
    use name <- decode.field("name", decode.string)
    use password <- decode.field("password", decode.string)
    decode.success(#(email, name, password))
  }
  json.parse(from: body, using: decoder)
  |> result.map_error(fn(_) { Nil })
}

fn decode_login_body(body: String) -> Result(#(String, String), Nil) {
  let decoder = {
    use email <- decode.field("email", decode.string)
    use password <- decode.field("password", decode.string)
    decode.success(#(email, password))
  }
  json.parse(from: body, using: decoder)
  |> result.map_error(fn(_) { Nil })
}

fn auth_success_response(user: StoredUser, secret: String) -> Response {
  let tok = token.create(user.id, secret)
  server.json_response(
    200,
    json.object([
      #("token", json.string(tok)),
      #(
        "user",
        json.object([
          #("id", json.string(user.id)),
          #("email", json.string(user.email)),
          #("name", json.string(user.name)),
        ]),
      ),
    ])
    |> json.to_string,
  )
}

fn user_response(user: StoredUser) -> Response {
  server.json_response(
    200,
    json.object([
      #("id", json.string(user.id)),
      #("email", json.string(user.email)),
      #("name", json.string(user.name)),
    ])
    |> json.to_string,
  )
}

fn error_response(status: Int, message: String) -> Response {
  server.json_response(
    status,
    json.object([#("error", json.string(message))])
    |> json.to_string,
  )
}
