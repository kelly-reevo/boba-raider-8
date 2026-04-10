/// Drink HTTP handlers

import data/drink_store.{type StoreMessage}
import gleam/dynamic/decode
import gleam/erlang/process.{type Subject}
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/string
import shared.{
  type AverageRating, type CreateDrinkInput, type Drink, CreateDrinkInput,
  Conflict, InvalidInput, NotFound, tea_type_from_string, tea_type_to_string,
}
import web/server.{type Request, type Response, json_response}

/// Intermediate type for parsing
fn decode_create_input() -> decode.Decoder(CreateDrinkInput) {
  use name <- decode.field("name", decode.string)
  use tea_type_str <- decode.field("tea_type", decode.string)
  use price <- decode.optional_field("price", None, decode.optional(decode.float))
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use image_url <- decode.optional_field(
    "image_url",
    None,
    decode.optional(decode.string),
  )
  use is_signature <- decode.optional_field(
    "is_signature",
    False,
    decode.bool,
  )

  // Convert tea_type string to TeaType
  case tea_type_from_string(tea_type_str) {
    Ok(tea_type) ->
      decode.success(
        CreateDrinkInput(
          name: name,
          tea_type: tea_type,
          price: price,
          description: description,
          image_url: image_url,
          is_signature: is_signature,
        ),
      )
    Error(err) -> decode.failure(CreateDrinkInput("", shared.Black, None, None, None, False), err)
  }
}

/// Parse create drink input from JSON
fn parse_create_drink_input(body: String) -> Result(CreateDrinkInput, String) {
  case json.parse(body, decode_create_input()) {
    Ok(input) -> Ok(input)
    Error(json.UnexpectedEndOfInput) -> Error("Invalid JSON: unexpected end of input")
    Error(json.UnexpectedByte(byte)) -> Error("Invalid JSON: unexpected byte " <> byte)
    Error(json.UnexpectedSequence(seq)) -> Error("Invalid JSON: unexpected sequence " <> seq)
    Error(json.UnableToDecode(errors)) -> {
      let error_msg = decode_errors_to_string(errors)
      Error("Invalid input: " <> error_msg)
    }
  }
}

fn decode_errors_to_string(errors: List(decode.DecodeError)) -> String {
  case errors {
    [] -> "Unknown error"
    [first, ..] -> first.expected <> " expected, found " <> first.found
  }
}

/// Encode a drink to JSON
fn encode_drink(drink: Drink) -> json.Json {
  json.object([
    #("id", json.string(drink.id)),
    #("store_id", json.string(drink.store_id)),
    #("name", json.string(drink.name)),
    #("tea_type", json.string(tea_type_to_string(drink.tea_type))),
    #("price", encode_optional_float(drink.price)),
    #("description", encode_optional_string(drink.description)),
    #("image_url", encode_optional_string(drink.image_url)),
    #("is_signature", json.bool(drink.is_signature)),
    #("created_at", json.string(drink.created_at)),
    #("average_rating", encode_average_rating(drink.average_rating)),
  ])
}

fn encode_optional_float(opt: Option(Float)) -> json.Json {
  case opt {
    Some(f) -> json.float(f)
    None -> json.null()
  }
}

fn encode_optional_string(opt: Option(String)) -> json.Json {
  case opt {
    Some(s) -> json.string(s)
    None -> json.null()
  }
}

fn encode_average_rating(rating: AverageRating) -> json.Json {
  json.object([
    #("overall", encode_optional_float(rating.overall)),
    #("sweetness", encode_optional_float(rating.sweetness)),
    #("texture", encode_optional_float(rating.texture)),
    #("tea_strength", encode_optional_float(rating.tea_strength)),
  ])
}

/// Encode an error response
fn encode_error(message: String) -> json.Json {
  json.object([#("error", json.string(message))])
}

/// Extract store_id from path like /api/stores/:store_id/drinks
fn extract_store_id(path: String) -> Option(String) {
  // Path format: /api/stores/{store_id}/drinks
  case path {
    "/api/stores/" <> rest -> {
      case string.split(rest, "/") {
        [store_id, "drinks"] -> Some(store_id)
        _ -> None
      }
    }
    _ -> None
  }
}

/// Create drink handler - POST /api/stores/:store_id/drinks
pub fn create(
  request: Request,
  drink_store: Subject(StoreMessage),
) -> Response {
  case extract_store_id(request.path) {
    Some(store_id) -> {
      case parse_create_drink_input(request.body) {
        Ok(input) -> {
          case drink_store.create_drink(drink_store, store_id, input) {
            Ok(drink) -> {
              json_response(
                201,
                encode_drink(drink) |> json.to_string,
              )
            }
            Error(NotFound(msg)) -> {
              json_response(404, encode_error(msg) |> json.to_string)
            }
            Error(Conflict(msg)) -> {
              json_response(409, encode_error(msg) |> json.to_string)
            }
            Error(InvalidInput(msg)) -> {
              json_response(422, encode_error(msg) |> json.to_string)
            }
            Error(_) -> {
              json_response(
                500,
                encode_error("Internal server error") |> json.to_string,
              )
            }
          }
        }
        Error(err) -> {
          json_response(422, encode_error(err) |> json.to_string)
        }
      }
    }
    None -> {
      json_response(404, encode_error("Invalid path") |> json.to_string)
    }
  }
}
