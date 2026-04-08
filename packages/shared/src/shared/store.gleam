import gleam/json.{type Json}
import gleam/dynamic/decode

/// Unique identifier for a boba store
pub type StoreId {
  StoreId(String)
}

pub fn store_id_to_string(id: StoreId) -> String {
  let StoreId(value) = id
  value
}

/// Operating hours for a single day
pub type DayHours {
  DayHours(open: String, close: String)
  Closed
}

/// Weekly operating hours
pub type StoreHours {
  StoreHours(
    monday: DayHours,
    tuesday: DayHours,
    wednesday: DayHours,
    thursday: DayHours,
    friday: DayHours,
    saturday: DayHours,
    sunday: DayHours,
  )
}

/// Physical address of a store
pub type Address {
  Address(
    street: String,
    city: String,
    state: String,
    zip: String,
  )
}

/// A boba tea store
pub type Store {
  Store(
    id: StoreId,
    name: String,
    address: Address,
    hours: StoreHours,
    description: String,
  )
}

// --- Constructors ---

pub fn new(
  id: String,
  name: String,
  address: Address,
  hours: StoreHours,
  description: String,
) -> Store {
  Store(
    id: StoreId(id),
    name: name,
    address: address,
    hours: hours,
    description: description,
  )
}

pub fn default_hours() -> StoreHours {
  let weekday = DayHours(open: "10:00", close: "21:00")
  StoreHours(
    monday: weekday,
    tuesday: weekday,
    wednesday: weekday,
    thursday: weekday,
    friday: weekday,
    saturday: weekday,
    sunday: Closed,
  )
}

// --- JSON Encoding ---

pub fn store_to_json(store: Store) -> Json {
  json.object([
    #("id", json.string(store_id_to_string(store.id))),
    #("name", json.string(store.name)),
    #("address", address_to_json(store.address)),
    #("hours", hours_to_json(store.hours)),
    #("description", json.string(store.description)),
  ])
}

pub fn address_to_json(addr: Address) -> Json {
  json.object([
    #("street", json.string(addr.street)),
    #("city", json.string(addr.city)),
    #("state", json.string(addr.state)),
    #("zip", json.string(addr.zip)),
  ])
}

fn day_hours_to_json(dh: DayHours) -> Json {
  case dh {
    DayHours(open, close) ->
      json.object([
        #("open", json.string(open)),
        #("close", json.string(close)),
      ])
    Closed -> json.null()
  }
}

pub fn hours_to_json(hours: StoreHours) -> Json {
  json.object([
    #("monday", day_hours_to_json(hours.monday)),
    #("tuesday", day_hours_to_json(hours.tuesday)),
    #("wednesday", day_hours_to_json(hours.wednesday)),
    #("thursday", day_hours_to_json(hours.thursday)),
    #("friday", day_hours_to_json(hours.friday)),
    #("saturday", day_hours_to_json(hours.saturday)),
    #("sunday", day_hours_to_json(hours.sunday)),
  ])
}

// --- JSON Decoding ---

pub fn store_decoder() -> decode.Decoder(Store) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use address <- decode.field("address", address_decoder())
  use hours <- decode.field("hours", hours_decoder())
  use description <- decode.field("description", decode.string)
  decode.success(Store(
    id: StoreId(id),
    name: name,
    address: address,
    hours: hours,
    description: description,
  ))
}

pub fn address_decoder() -> decode.Decoder(Address) {
  use street <- decode.field("street", decode.string)
  use city <- decode.field("city", decode.string)
  use state <- decode.field("state", decode.string)
  use zip <- decode.field("zip", decode.string)
  decode.success(Address(street: street, city: city, state: state, zip: zip))
}

fn day_hours_decoder() -> decode.Decoder(DayHours) {
  use open <- decode.field("open", decode.string)
  use close <- decode.field("close", decode.string)
  decode.success(DayHours(open: open, close: close))
}

fn nullable_day_hours_decoder() -> decode.Decoder(DayHours) {
  decode.one_of(day_hours_decoder(), [
    decode.success(Closed)
      |> decode.map(fn(_) { Closed }),
  ])
}

pub fn hours_decoder() -> decode.Decoder(StoreHours) {
  use monday <- decode.field("monday", nullable_day_hours_decoder())
  use tuesday <- decode.field("tuesday", nullable_day_hours_decoder())
  use wednesday <- decode.field("wednesday", nullable_day_hours_decoder())
  use thursday <- decode.field("thursday", nullable_day_hours_decoder())
  use friday <- decode.field("friday", nullable_day_hours_decoder())
  use saturday <- decode.field("saturday", nullable_day_hours_decoder())
  use sunday <- decode.field("sunday", nullable_day_hours_decoder())
  decode.success(StoreHours(
    monday: monday,
    tuesday: tuesday,
    wednesday: wednesday,
    thursday: thursday,
    friday: friday,
    saturday: saturday,
    sunday: sunday,
  ))
}
