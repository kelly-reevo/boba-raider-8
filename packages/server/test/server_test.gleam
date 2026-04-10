import gleeunit
import gleeunit/should
import config
import users

pub fn main() {
  gleeunit.main()
}

pub fn config_load_test() {
  let cfg = config.load()
  cfg.port
  |> should.equal(3000)
}

// User registration tests

pub fn parse_register_request_valid_test() {
  let json = "{\"email\":\"test@example.com\",\"username\":\"testuser\",\"password\":\"Password123\"}"
  let result = users.parse_register_request(json)

  case result {
    Ok(req) -> {
      req.email |> should.equal("test@example.com")
      req.username |> should.equal("testuser")
      req.password |> should.equal("Password123")
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_register_request_missing_field_test() {
  let json = "{\"email\":\"test@example.com\",\"username\":\"testuser\"}"
  let result = users.parse_register_request(json)

  result |> should.be_error()
}

pub fn validate_registration_valid_test() {
  let req = users.RegisterRequest(
    email: "test@example.com",
    username: "testuser",
    password: "Password123",
  )

  let errors = users.validate_registration(req)
  errors |> should.equal([])
}

pub fn validate_registration_invalid_email_test() {
  let req = users.RegisterRequest(
    email: "invalid-email",
    username: "testuser",
    password: "Password123",
  )

  let errors = users.validate_registration(req)
  errors |> should.not_equal([])
}

pub fn validate_registration_short_password_test() {
  let req = users.RegisterRequest(
    email: "test@example.com",
    username: "testuser",
    password: "short",
  )

  let errors = users.validate_registration(req)
  errors |> should.not_equal([])
}

pub fn validate_registration_password_no_uppercase_test() {
  let req = users.RegisterRequest(
    email: "test@example.com",
    username: "testuser",
    password: "password123",
  )

  let errors = users.validate_registration(req)
  let has_uppercase_error = errors |> list.any(fn(e) {
    string.contains(e.message, "uppercase")
  })
  has_uppercase_error |> should.be_true()
}

pub fn validate_registration_password_no_number_test() {
  let req = users.RegisterRequest(
    email: "test@example.com",
    username: "testuser",
    password: "PasswordNoNumber",
  )

  let errors = users.validate_registration(req)
  let has_number_error = errors |> list.any(fn(e) {
    string.contains(e.message, "number")
  })
  has_number_error |> should.be_true()
}

pub fn validate_registration_short_username_test() {
  let req = users.RegisterRequest(
    email: "test@example.com",
    username: "ab",
    password: "Password123",
  )

  let errors = users.validate_registration(req)
  errors |> should.not_equal([])
}

pub fn validate_registration_empty_fields_test() {
  let req = users.RegisterRequest(
    email: "",
    username: "",
    password: "",
  )

  let errors = users.validate_registration(req)
  // Should have errors for all three fields
  errors |> list.length() |> should.equal(3)
}

pub fn user_to_json_test() {
  let user = users.User(
    id: "123-456",
    email: "test@example.com",
    username: "testuser",
    password_hash: "hash123",
    created_at: "2024-01-01T00:00:00Z",
  )

  let json = users.user_to_json(user)
  let json_str = json.to_string(json)

  json_str |> string.contains("\"id\":\"123-456\"") |> should.be_true()
  json_str |> string.contains("\"email\":\"test@example.com\"") |> should.be_true()
  json_str |> string.contains("\"username\":\"testuser\"") |> should.be_true()
  json_str |> string.contains("\"created_at\"") |> should.be_true()
  // Password hash should NOT be in the response
  json_str |> string.contains("password_hash") |> should.be_false()
}

pub fn errors_to_json_test() {
  let errors = [
    users.FieldError("email", "Invalid format"),
    users.FieldError("password", "Too short"),
  ]

  let json = users.errors_to_json(errors)
  let json_str = json.to_string(json)

  json_str |> string.contains("\"errors\"") |> should.be_true()
  json_str |> string.contains("\"field\":\"email\"") |> should.be_true()
  json_str |> string.contains("\"message\":\"Invalid format\"") |> should.be_true()
}

// Import required for tests
import gleam/list
import gleam/string
import gleam/json
