import gleeunit
import gleeunit/should
import gleam/dict
import gleam/dynamic/decode
import gleam/json
import config
import web/auth/jwt
import web/auth/login
import web/server.{Request}
import web/user_store

pub fn main() {
  gleeunit.main()
}

pub fn config_load_test() {
  let cfg = config.load()
  cfg.port
  |> should.equal(3000)
}

// Test successful login with valid credentials
pub fn login_with_valid_credentials_test() {
  let assert Ok(store) = user_store.start()
  let jwt_secret = "test-secret"

  // Add a test user
  let test_user =
    user_store.User(
      id: "user-123",
      email: "test@example.com",
      username: "testuser",
      password_hash: user_store.hash_password("password123"),
    )
  user_store.add_user(store, test_user)

  // Create login request
  let request_body =
    json.object([
      #("email", json.string("test@example.com")),
      #("password", json.string("password123")),
    ])
    |> json.to_string

  let request = Request(
    method: "POST",
    path: "/api/auth/login",
    headers: dict.new(),
    body: request_body,
  )

  // Execute login
  let response = login.handle_login(request, store, jwt_secret)

  // Verify response
  response.status |> should.equal(200)

  // Parse response body and check structure
  let body_json = json.parse(response.body, response_decoder())
  should.be_ok(body_json)

  // Verify tokens and user data
  let assert Ok(#(access_token, refresh_token, email)) = body_json
  access_token |> should.not_equal("")
  refresh_token |> should.not_equal("")
  email |> should.equal("test@example.com")
}

// Test login with invalid credentials
pub fn login_with_invalid_password_test() {
  let assert Ok(store) = user_store.start()
  let jwt_secret = "test-secret"

  // Add a test user
  let test_user =
    user_store.User(
      id: "user-123",
      email: "test@example.com",
      username: "testuser",
      password_hash: user_store.hash_password("password123"),
    )
  user_store.add_user(store, test_user)

  // Create login request with wrong password
  let request_body =
    json.object([
      #("email", json.string("test@example.com")),
      #("password", json.string("wrongpassword")),
    ])
    |> json.to_string

  let request = Request(
    method: "POST",
    path: "/api/auth/login",
    headers: dict.new(),
    body: request_body,
  )

  // Execute login
  let response = login.handle_login(request, store, jwt_secret)

  // Verify 401 response
  response.status |> should.equal(401)
  response.body |> should.not_equal("")
}

// Test login with non-existent user
pub fn login_with_nonexistent_user_test() {
  let assert Ok(store) = user_store.start()
  let jwt_secret = "test-secret"

  // Create login request for user that doesn't exist
  let request_body =
    json.object([
      #("email", json.string("nobody@example.com")),
      #("password", json.string("password123")),
    ])
    |> json.to_string

  let request = Request(
    method: "POST",
    path: "/api/auth/login",
    headers: dict.new(),
    body: request_body,
  )

  // Execute login
  let response = login.handle_login(request, store, jwt_secret)

  // Verify 401 response
  response.status |> should.equal(401)
}

// Test login with missing fields
pub fn login_with_missing_fields_test() {
  let assert Ok(store) = user_store.start()
  let jwt_secret = "test-secret"

  // Create login request with missing password
  let request_body =
    json.object([
      #("email", json.string("test@example.com")),
      #("password", json.string("")),
    ])
    |> json.to_string

  let request = Request(
    method: "POST",
    path: "/api/auth/login",
    headers: dict.new(),
    body: request_body,
  )

  // Execute login
  let response = login.handle_login(request, store, jwt_secret)

  // Verify 400 response
  response.status |> should.equal(400)
}

// Test JWT token generation and verification
pub fn jwt_token_generation_and_verification_test() {
  let jwt_secret = "test-secret"
  let user_id = "user-456"
  let email = "jwt@example.com"
  let username = "jwttest"

  // Generate tokens
  let assert Ok(#(access_token, refresh_token)) =
    jwt.generate_tokens(user_id, email, username, jwt_secret)

  // Verify tokens are non-empty
  access_token |> should.not_equal("")
  refresh_token |> should.not_equal("")

  // Verify access token can be decoded
  let assert Ok(#(decoded_id, decoded_email, decoded_username)) =
    jwt.verify_access_token(access_token, jwt_secret)

  decoded_id |> should.equal(user_id)
  decoded_email |> should.equal(email)
  decoded_username |> should.equal(username)
}

// Test JWT verification with wrong secret
pub fn jwt_wrong_secret_test() {
  let jwt_secret = "test-secret"
  let wrong_secret = "wrong-secret"
  let user_id = "user-789"
  let email = "test@example.com"
  let username = "testuser"

  // Generate token with correct secret
  let assert Ok(#(access_token, _)) =
    jwt.generate_tokens(user_id, email, username, jwt_secret)

  // Verify with wrong secret should fail
  jwt.verify_access_token(access_token, wrong_secret)
  |> should.be_error
}

// Response decoder for login response
fn response_decoder() {
  use access_token <- decode.field("access_token", decode.string)
  use refresh_token <- decode.field("refresh_token", decode.string)
  use user <- decode.field(
    "user",
    decode.field("email", decode.string, fn(email) { decode.success(email) }),
  )
  decode.success(#(access_token, refresh_token, user))
}
