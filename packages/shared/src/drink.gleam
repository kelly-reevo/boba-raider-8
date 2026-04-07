/// Drink domain type with store association

import gleam/dynamic/decode
import gleam/json.{type Json}

pub type Drink {
  Drink(id: String, name: String, description: String, store_id: String)
}

pub fn to_json(drink: Drink) -> Json {
  json.object([
    #("id", json.string(drink.id)),
    #("name", json.string(drink.name)),
    #("description", json.string(drink.description)),
    #("store_id", json.string(drink.store_id)),
  ])
}

pub fn decoder() -> decode.Decoder(Drink) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.string)
  use store_id <- decode.field("store_id", decode.string)
  decode.success(Drink(id: id, name: name, description: description, store_id: store_id))
}
