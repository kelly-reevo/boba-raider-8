import gleam/erlang/atom
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/otp/actor

/// User record stored in the system
pub type User {
  User(
    id: String,
    email: String,
    username: String,
    password_hash: String,
    created_at: String,
  )
}

/// Registration request from client
pub type RegisterRequest {
  RegisterRequest(
    email: String,
    username: String,
    password: String,
  )
}

/// Validation error for a specific field
pub type FieldError {
  FieldError(field: String, message: String)
}

/// Result of registration attempt
pub type RegisterResult {
  RegisterSuccess(User)
  RegisterValidationError(List(FieldError))
  RegisterConflict(String)
}

/// Parse registration request from JSON using manual parsing
pub fn parse_register_request(body: String) -> Result(RegisterRequest, String) {
  // Extract email
  let email = extract_json_field(body, "email")
  let username = extract_json_field(body, "username")
  let password = extract_json_field(body, "password")

  case email, username, password {
    Ok(e), Ok(u), Ok(p) -> Ok(RegisterRequest(email: e, username: u, password: p))
    Error(_), _, _ -> Error("Missing or invalid email field")
    _, Error(_), _ -> Error("Missing or invalid username field")
    _, _, Error(_) -> Error("Missing or invalid password field")
  }
}

/// Simple JSON field extraction
fn extract_json_field(json: String, field: String) -> Result(String, Nil) {
  let pattern = "\"" <> field <> "\":"
  case string.split(json, pattern) {
    [_, rest, ..] -> {
      // Find the value after the field name
      let trimmed = string.trim(rest)
      case string.starts_with(trimmed, "\"") {
        True -> {
          // String value
          let after_quote = string.slice(trimmed, 1, string.length(trimmed) - 1)
          case string.split(after_quote, "\"") {
            [value, ..] -> Ok(value)
            _ -> Error(Nil)
          }
        }
        False -> {
          // Non-string value (take until comma or brace)
          let end_marker = case string.contains(trimmed, ",") {
            True -> ","
            False -> "}"
          }
          case string.split(trimmed, end_marker) {
            [value, ..] -> Ok(string.trim(value))
            _ -> Error(Nil)
          }
        }
      }
    }
    _ -> Error(Nil)
  }
}

/// Validate email format using simple checks
fn validate_email_format(email: String) -> Result(Nil, String) {
  // Simple email validation without regex
  let has_at = string.contains(email, "@")
  let has_dot_after_at = case string.split(email, "@") {
    [_, domain, ..] -> string.contains(domain, ".")
    _ -> False
  }
  let no_spaces = !string.contains(email, " ")
  let not_empty = !string.is_empty(email)

  case has_at && has_dot_after_at && no_spaces && not_empty {
    True -> Ok(Nil)
    False -> Error("Invalid email format")
  }
}

/// Check if character is uppercase
fn is_uppercase(char: String) -> Bool {
  case string.to_utf_codepoints(char) {
    [cp, ..] -> {
      let code = string.utf_codepoint_to_int(cp)
      code >= 65 && code <= 90
    }
    [] -> False
  }
}

/// Check if character is a digit
fn is_digit(char: String) -> Bool {
  case string.to_utf_codepoints(char) {
    [cp, ..] -> {
      let code = string.utf_codepoint_to_int(cp)
      code >= 48 && code <= 57
    }
    [] -> False
  }
}

/// Validate password strength (min 8 chars, 1 uppercase, 1 number)
fn validate_password_strength(password: String) -> List(String) {
  let errors = []

  let errors = case string.length(password) >= 8 {
    True -> errors
    False -> ["Password must be at least 8 characters", ..errors]
  }

  let chars = string.to_graphemes(password)

  let has_uppercase = list.any(chars, is_uppercase)
  let errors = case has_uppercase {
    True -> errors
    False -> ["Password must contain at least one uppercase letter", ..errors]
  }

  let has_number = list.any(chars, is_digit)
  let errors = case has_number {
    True -> errors
    False -> ["Password must contain at least one number", ..errors]
  }

  list.reverse(errors)
}

/// Validate all registration fields
pub fn validate_registration(req: RegisterRequest) -> List(FieldError) {
  let errors = []

  // Email validation
  let errors = case string.is_empty(req.email) {
    True -> [FieldError("email", "Email is required"), ..errors]
    False -> {
      case validate_email_format(req.email) {
        Ok(Nil) -> errors
        Error(msg) -> [FieldError("email", msg), ..errors]
      }
    }
  }

  // Username validation
  let errors = case string.is_empty(req.username) {
    True -> [FieldError("username", "Username is required"), ..errors]
    False -> {
      case string.length(req.username) >= 3 {
        True -> errors
        False -> [FieldError("username", "Username must be at least 3 characters"), ..errors]
      }
    }
  }

  // Password validation
  let errors = case string.is_empty(req.password) {
    True -> [FieldError("password", "Password is required"), ..errors]
    False -> {
      let pw_errors = validate_password_strength(req.password)
      list.map(pw_errors, fn(msg) { FieldError("password", msg) }) |> list.append(errors)
    }
  }

  list.reverse(errors)
}

/// Hash password using Erlang crypto (SHA-256 based for simplicity)
@external(erlang, "crypto", "hash")
fn crypto_hash(algorithm: atom.Atom, data: BitArray) -> BitArray

@external(erlang, "base64", "encode")
fn base64_encode(data: BitArray) -> String

/// Generate a hash from password
fn hash_password(password: String) -> String {
  let sha256 = atom.create("sha256")
  crypto_hash(sha256, <<password:utf8>>)
  |> base64_encode()
}

/// Generate unique ID
fn generate_id() -> String {
  let timestamp = int.to_string(erlang_system_time_microsecond())
  let random = int.to_string(int.random(1_000_000))
  timestamp <> "-" <> random
}

@external(erlang, "erlang", "system_time")
fn erlang_system_time_microsecond() -> Int

/// Get current timestamp
fn now_iso8601() -> String {
  let seconds = erlang_system_time_second()
  let sec_int = seconds % 60
  let min_int = { seconds / 60 } % 60
  let hour_int = { seconds / 3600 } % 24

  int.to_string(2024) <> "-" <> pad2(1) <> "-" <> pad2(1) <> "T"
  <> pad2(hour_int) <> ":" <> pad2(min_int) <> ":" <> pad2(sec_int) <> "Z"
}

@external(erlang, "erlang", "system_time")
fn erlang_system_time_second() -> Int

fn pad2(n: Int) -> String {
  let s = int.to_string(n)
  case string.length(s) {
    1 -> "0" <> s
    _ -> s
  }
}

/// User store message types
pub type UserStoreMsg {
  GetUserByEmail(String, Subject(Option(User)))
  CreateUser(User, Subject(Result(Nil, String)))
}

/// State for the user store actor
pub type UserStoreState {
  UserStoreState(users: List(User))
}

/// Initialize the user store with in-memory list storage
pub fn init_store() -> Result(Subject(UserStoreMsg), String) {
  actor.new(UserStoreState(users: []))
  |> actor.on_message(fn(state, msg) {
    case msg {
      GetUserByEmail(email, reply_to) -> {
        let user = case list.find(state.users, fn(u) { u.email == email }) {
          Ok(u) -> Some(u)
          Error(_) -> None
        }
        process.send(reply_to, user)
        actor.continue(state)
      }
      CreateUser(user, reply_to) -> {
        let new_state = UserStoreState(users: [user, ..state.users])
        process.send(reply_to, Ok(Nil))
        actor.continue(new_state)
      }
    }
  })
  |> actor.start()
  |> result.map(fn(started) { started.data })
  |> result.map_error(fn(_) { "Failed to start user store" })
}

/// Register a new user
pub fn register(
  store: Subject(UserStoreMsg),
  req: RegisterRequest,
) -> RegisterResult {
  // Validate input
  let validation_errors = validate_registration(req)
  case validation_errors {
    [] -> {
      // Check if email already exists
      let reply_subject = process.new_subject()
      process.send(store, GetUserByEmail(req.email, reply_subject))

      case process.receive(reply_subject, 5000) {
        Ok(Some(_)) -> RegisterConflict("Email already registered")
        Ok(None) -> {
          // Create user
          let user = User(
            id: generate_id(),
            email: req.email,
            username: req.username,
            password_hash: hash_password(req.password),
            created_at: now_iso8601(),
          )

          // Store user
          let create_reply = process.new_subject()
          process.send(store, CreateUser(user, create_reply))

          case process.receive(create_reply, 5000) {
            Ok(Ok(Nil)) -> RegisterSuccess(user)
            _ -> RegisterValidationError([FieldError("", "Failed to create user")])
          }
        }
        _ -> RegisterValidationError([FieldError("", "Failed to check email availability")])
      }
    }
    errors -> RegisterValidationError(errors)
  }
}

/// Convert user to JSON response
pub fn user_to_json(user: User) -> Json {
  json.object([
    #("id", json.string(user.id)),
    #("email", json.string(user.email)),
    #("username", json.string(user.username)),
    #("created_at", json.string(user.created_at)),
  ])
}

/// Convert validation errors to JSON
pub fn errors_to_json(errors: List(FieldError)) -> Json {
  json.object([
    #("errors", json.array(errors, fn(e) {
      json.object([
        #("field", json.string(e.field)),
        #("message", json.string(e.message)),
      ])
    })),
  ])
}
