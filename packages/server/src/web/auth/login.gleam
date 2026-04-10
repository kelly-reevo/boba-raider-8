import gleam/dynamic/decode
import gleam/json
import web/auth/jwt
import web/server.{type Request, type Response, json_response}
import web/user_store.{
  type User, type UserStore, find_by_email, verify_password,
}

/// Login request body
pub type LoginRequest {
  LoginRequest(email: String, password: String)
}

/// Login success response
pub type LoginResponse {
  LoginResponse(
    access_token: String,
    refresh_token: String,
    user: UserProfile,
  )
}

pub type UserProfile {
  UserProfile(id: String, email: String, username: String)
}

/// Login error response
pub type LoginError {
  InvalidCredentials
  MissingFields
  InvalidJson
}

/// Handle POST /api/auth/login
pub fn handle_login(
  request: Request,
  store: UserStore,
  jwt_secret: String,
) -> Response {
  case parse_request(request.body) {
    Ok(LoginRequest(email, password)) -> {
      case authenticate_user(email, password, store) {
        Ok(user) -> {
          case
            jwt.generate_tokens(user.id, user.email, user.username, jwt_secret)
          {
            Ok(#(access_token, refresh_token)) -> {
              let response =
                LoginResponse(
                  access_token: access_token,
                  refresh_token: refresh_token,
                  user: UserProfile(user.id, user.email, user.username),
                )
              json_response(200, encode_success_response(response))
            }
            Error(_) -> {
              json_response(500, encode_error_response("Token generation failed"))
            }
          }
        }
        Error(_) -> {
          json_response(401, encode_error_response("Invalid credentials"))
        }
      }
    }
    Error(MissingFields) -> {
      json_response(400, encode_error_response("Missing email or password"))
    }
    Error(InvalidJson) -> {
      json_response(400, encode_error_response("Invalid JSON"))
    }
    Error(InvalidCredentials) -> {
      json_response(401, encode_error_response("Invalid credentials"))
    }
  }
}

/// Parse and validate login request
fn parse_request(body: String) -> Result(LoginRequest, LoginError) {
  case json.parse(body, login_request_decoder()) {
    Ok(#(email, password)) -> {
      case email == "" || password == "" {
        True -> Error(MissingFields)
        False -> Ok(LoginRequest(email, password))
      }
    }
    Error(_) -> Error(InvalidJson)
  }
}

fn login_request_decoder() {
  use email <- decode.field("email", decode.string)
  use password <- decode.field("password", decode.string)
  decode.success(#(email, password))
}

/// Authenticate user against store
fn authenticate_user(
  email: String,
  password: String,
  store: UserStore,
) -> Result(User, Nil) {
  case find_by_email(store, email) {
    Ok(user) -> {
      case verify_password(password, user.password_hash) {
        True -> Ok(user)
        False -> Error(Nil)
      }
    }
    Error(_) -> Error(Nil)
  }
}

/// Encode successful login response
fn encode_success_response(response: LoginResponse) -> String {
  json.object([
    #("access_token", json.string(response.access_token)),
    #("refresh_token", json.string(response.refresh_token)),
    #(
      "user",
      json.object([
        #("id", json.string(response.user.id)),
        #("email", json.string(response.user.email)),
        #("username", json.string(response.user.username)),
      ]),
    ),
  ])
  |> json.to_string
}

/// Encode error response
fn encode_error_response(message: String) -> String {
  json.object([#("error", json.string(message))])
  |> json.to_string
}
