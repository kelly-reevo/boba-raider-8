import gleam/dynamic/decode
import gleam/json

pub type Drink {
  Drink(id: String, name: String, shop: String)
}

pub fn encoder(drink: Drink) -> json.Json {
  json.object([
    #("id", json.string(drink.id)),
    #("name", json.string(drink.name)),
    #("shop", json.string(drink.shop)),
  ])
}

pub fn decoder() -> decode.Decoder(Drink) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use shop <- decode.field("shop", decode.string)
  decode.success(Drink(id:, name:, shop:))
}
