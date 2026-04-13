/// Boba Router - HTTP request router for boba API endpoints
/// Handles drink CRUD operations with store integration
import drink_store.{type DrinkStore}
import gleam/dict
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import services/drink_service
import store/store_data_access as store_access
import web/server.{type Request, type Response}

/// Create a request handler with store access
pub fn make_handler(store: DrinkStore) -> fn(Request) -> Response {
  fn(request: Request) { route(request, store) }
}

/// Main routing logic
fn route(request: Request, store: DrinkStore) -> Response {
  case request.method, request.path {
    "PUT", path -> route_put(path, request, store)
    _, _ -> not_found()
  }
}

/// Handle PUT requests
fn route_put(path: String, request: Request, store: DrinkStore) -> Response {
  case string.starts_with(path, "/api/drinks/") {
    True -> {
      let id = string.drop_start(path, 12)
      put_drink_handler(id, request, store)
    }
    False -> not_found()
  }
}

/// PUT /api/drinks/:id handler
/// Updates drink fields with partial update support
fn put_drink_handler(
  id: String,
  request: Request,
  store: DrinkStore,
) -> Response {
  // Parse the request body using a decoder
  case parse_update_request(request.body) {
    Error(_) ->
      json_response(
        400,
        json.object([#("error", json.string("Invalid JSON body"))]),
      )
    Ok(parsed) -> {
      // Build update input with Option(Option(T)) for null handling
      let input =
        drink_service.UpdateDrinkServiceInput(
          name: parsed.name,
          description: parsed.description,
          base_tea_type: parsed.base_tea_type,
          price: parsed.price,
        )

      // Call service layer
      let store_state = store_access.global_state()
      case drink_service.update_drink(store, store_state, id, input) {
        Ok(drink_output) -> {
          // Serialize drink output to JSON
          let body = encode_drink_output(drink_output)
          json_response(200, body)
        }
        Error(errors) -> {
          // Check if this is a "not found" error vs validation errors
          case
            list.find(errors, fn(e) {
              e.field == "id" && e.message == "Drink not found"
            })
          {
            Ok(_) -> not_found()
            Error(_) -> {
              // Return 422 with validation errors
              let errors_json =
                list.map(errors, fn(e) {
                  json.object([
                    #("field", json.string(e.field)),
                    #("message", json.string(e.message)),
                  ])
                })
              json_response(
                422,
                json.object([
                  #("errors", json.array(errors_json, of: fn(x) { x })),
                ]),
              )
            }
          }
        }
      }
    }
  }
}

/// Parsed update request fields - all optional for partial updates
/// Uses Option(Option(T)) to distinguish between:
/// - None: field not provided (keep existing)
/// - Some(None): field set to null (clear field)
/// - Some(Some(T)): field set to new value
type ParsedUpdateRequest {
  ParsedUpdateRequest(
    name: Option(String),
    description: Option(Option(String)),
    base_tea_type: Option(Option(String)),
    price: Option(Option(Float)),
  )
}

/// Parse JSON body for update request
fn parse_update_request(
  body: String,
) -> Result(ParsedUpdateRequest, json.DecodeError) {
  // Decoder for each field type:
  // - name: Option(String) - absent=None, present=Some(value)
  // - description/base_tea_type/price: Option(Option(T)) - absent=None, null=Some(None), value=Some(Some(v))
  let decoder = {
    use name <- decode.field("name", decode.optional(decode.string))
    use description <- decode.field(
      "description",
      decode.optional(decode.optional(decode.string)),
    )
    use base_tea_type <- decode.field(
      "base_tea_type",
      decode.optional(decode.optional(decode.string)),
    )
    use price <- decode.field(
      "price",
      decode.optional(decode.optional(decode.float)),
    )
    decode.success(ParsedUpdateRequest(
      name:,
      description:,
      base_tea_type:,
      price:,
    ))
  }

  json.parse(from: body, using: decoder)
}

/// Encode DrinkOutput to JSON object
fn encode_drink_output(drink: drink_service.DrinkOutput) -> json.Json {
  json.object([
    #("id", json.string(drink.id)),
    #("name", json.string(drink.name)),
    #("description", case drink.description {
      Some(d) -> json.string(d)
      None -> json.null()
    }),
    #("base_tea_type", case drink.base_tea_type {
      Some(t) -> json.string(t)
      None -> json.null()
    }),
    #("price", case drink.price {
      Some(p) -> json.float(p)
      None -> json.null()
    }),
    #("updated_at", json.string(drink.updated_at)),
  ])
}

/// Helper: Create JSON response
fn json_response(status: Int, body: json.Json) -> Response {
  server.Response(
    status: status,
    headers: dict.from_list([#("Content-Type", "application/json")]),
    body: json.to_string(body),
  )
}

/// Helper: 404 not found response
fn not_found() -> Response {
  json_response(404, json.object([#("error", json.string("Not found"))]))
}
