/// Shared types and functions for boba-raider-8

import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

pub type AppError {
  NotFound(String)
  InvalidInput(String)
  InternalError(String)
  Conflict(String)
  Unauthorized(String)
}

/// Convert an error to a human-readable message
pub fn error_message(error: AppError) -> String {
  case error {
    NotFound(msg) -> "Not found: " <> msg
    InvalidInput(msg) -> "Invalid input: " <> msg
    InternalError(msg) -> "Internal error: " <> msg
    Conflict(msg) -> "Conflict: " <> msg
    Unauthorized(msg) -> "Unauthorized: " <> msg
  }
}

/// Store represents a boba tea shop
pub type Store {
  Store(
    id: String,
    name: String,
    address: String,
    lat: Float,
    lng: Float,
    phone: String,
    hours: String,
    description: String,
    image_url: String,
    created_by: String,
    created_at: String,
    average_rating: Float,
  )
}

/// Store JSON encoder
pub fn store_to_json(store: Store) -> Json {
  json.object([
    #("id", json.string(store.id)),
    #("name", json.string(store.name)),
    #("address", json.string(store.address)),
    #("lat", json.float(store.lat)),
    #("lng", json.float(store.lng)),
    #("phone", json.string(store.phone)),
    #("hours", json.string(store.hours)),
    #("description", json.string(store.description)),
    #("image_url", json.string(store.image_url)),
    #("created_by", json.string(store.created_by)),
    #("created_at", json.string(store.created_at)),
    #("average_rating", json.float(store.average_rating)),
  ])
}

/// CreateStoreRequest for creating a new store
pub type CreateStoreRequest {
  CreateStoreRequest(
    name: String,
    address: String,
    phone: Option(String),
    hours: Option(String),
    description: Option(String),
    image_url: Option(String),
  )
}

/// Decoder for optional string field with None default
fn optional_string_field(
  key: String,
  next: fn(Option(String)) -> decode.Decoder(final),
) -> decode.Decoder(final) {
  decode.optional_field(key, None, {
    decode.string
    |> decode.map(fn(s) { Some(s) })
  }, next)
}

/// Decoder for CreateStoreRequest
fn create_store_request_decoder() -> decode.Decoder(CreateStoreRequest) {
  use name <- decode.field("name", decode.string)
  use address <- decode.field("address", decode.string)
  use phone <- optional_string_field("phone", _)
  use hours <- optional_string_field("hours", _)
  use description <- optional_string_field("description", _)
  use image_url <- optional_string_field("image_url", _)
  decode.success(CreateStoreRequest(
    name: name,
    address: address,
    phone: phone,
    hours: hours,
    description: description,
    image_url: image_url,
  ))
}

/// Decode CreateStoreRequest from JSON
pub fn decode_create_store_request(
  body: String,
) -> Result(CreateStoreRequest, String) {
  let decoder = create_store_request_decoder()
  case json.parse(body, decoder) {
    Ok(request) -> {
      // Validate required fields are not empty
      case string.is_empty(request.name), string.is_empty(request.address) {
        True, _ -> Error("name is required and cannot be empty")
        _, True -> Error("address is required and cannot be empty")
        False, False -> Ok(request)
      }
    }
    Error(err) -> {
      let error_msg = case err {
        json.UnexpectedEndOfInput -> "Invalid JSON: unexpected end of input"
        json.UnexpectedByte(byte) -> "Invalid JSON: unexpected byte " <> byte
        json.UnexpectedSequence(seq) -> "Invalid JSON: unexpected sequence " <> seq
        json.UnableToDecode(decode_errors) -> {
          decode_errors
          |> list.map(fn(e) { string.join(e.path, ".") <> ": " <> e.expected })
          |> string.join(", ")
        }
      }
      Error(error_msg)
    }
  }
}

/// Geocoded coordinates
pub type Coordinates {
  Coordinates(lat: Float, lng: Float)
}

/// Error response encoder
pub fn error_to_json(error: AppError) -> Json {
  json.object([#("error", json.string(error_message(error)))])
}

/// Encode list of stores
pub fn stores_to_json(stores: List(Store)) -> Json {
  json.array(stores, store_to_json)
}
