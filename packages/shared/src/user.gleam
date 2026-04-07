import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/option.{type Option, None}

pub type User {
  User(
    id: String,
    username: String,
    email: String,
    display_name: Option(String),
    bio: Option(String),
  )
}

pub fn to_json(user: User) -> Json {
  json.object([
    #("id", json.string(user.id)),
    #("username", json.string(user.username)),
    #("email", json.string(user.email)),
    #("display_name", json.nullable(user.display_name, json.string)),
    #("bio", json.nullable(user.bio, json.string)),
  ])
}

pub fn decoder() -> decode.Decoder(User) {
  use id <- decode.field("id", decode.string)
  use username <- decode.field("username", decode.string)
  use email <- decode.field("email", decode.string)
  use display_name <- decode.optional_field("display_name", None, decode.optional(decode.string))
  use bio <- decode.optional_field("bio", None, decode.optional(decode.string))
  decode.success(User(
    id: id,
    username: username,
    email: email,
    display_name: display_name,
    bio: bio,
  ))
}

/// Create a new user with required fields only
pub fn new(id: String, username: String, email: String) -> User {
  User(id: id, username: username, email: email, display_name: None, bio: None)
}

/// Update profile fields on a user
pub fn with_profile(
  user: User,
  display_name: Option(String),
  bio: Option(String),
) -> User {
  User(..user, display_name: display_name, bio: bio)
}
