import gleam/dynamic/decode
import gleam/json

pub type Drink {
  Drink(
    id: String,
    store_id: String,
    name: String,
    description: String,
    price_cents: Int,
    category: String,
    available: Bool,
  )
}

pub fn to_json(drink: Drink) -> json.Json {
  json.object([
    #("id", json.string(drink.id)),
    #("store_id", json.string(drink.store_id)),
    #("name", json.string(drink.name)),
    #("description", json.string(drink.description)),
    #("price_cents", json.int(drink.price_cents)),
    #("category", json.string(drink.category)),
    #("available", json.bool(drink.available)),
  ])
}

pub fn decoder() -> decode.Decoder(Drink) {
  use id <- decode.optional_field("id", "", decode.string)
  use store_id <- decode.optional_field("store_id", "", decode.string)
  use name <- decode.field("name", decode.string)
  use description <- decode.optional_field("description", "", decode.string)
  use price_cents <- decode.field("price_cents", decode.int)
  use category <- decode.optional_field("category", "", decode.string)
  use available <- decode.optional_field("available", True, decode.bool)
  decode.success(Drink(id, store_id, name, description, price_cents, category, available))
}

pub fn list_to_json(drinks: List(Drink)) -> json.Json {
  json.array(drinks, to_json)
}
