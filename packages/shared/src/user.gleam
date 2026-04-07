import gleam/dynamic/decode
import gleam/json

pub type User {
  User(id: String, username: String, email: String)
}

pub fn encoder(user: User) -> json.Json {
  json.object([
    #("id", json.string(user.id)),
    #("username", json.string(user.username)),
    #("email", json.string(user.email)),
  ])
}

pub fn decoder() -> decode.Decoder(User) {
  use id <- decode.field("id", decode.string)
  use username <- decode.field("username", decode.string)
  use email <- decode.field("email", decode.string)
  decode.success(User(id:, username:, email:))
}
