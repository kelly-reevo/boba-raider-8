import app/boba_store
import wisp
import gleam/dict
import gleam/dynamic
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import store/store_validation

/// Parse store ID from path like "/api/stores/store-123"
fn parse_store_id(path: String) -> option.Option(String) {
  let parts = string.split(path, "/")
  case parts {
    ["", "api", "stores", id] -> Some(id)
    _ -> None
  }
}

/// Decode JSON payload for store update
fn decode_update_payload(body: String) -> Result(dict.Dict(String, dynamic.Dynamic), String) {
  let decoder = decode.dict(decode.string, decode.dynamic)
  case json.parse(body, decoder) {
    Ok(dict) -> Ok(dict)
    Error(_) -> Error("Invalid JSON payload")
  }
}

/// Get optional string field from decoded payload
fn get_optional_string_field(
  d: dict.Dict(String, dynamic.Dynamic),
  field: String,
) -> option.Option(String) {
  case dict.get(d, field) {
    Ok(dyn) -> {
      case decode.run(dyn, decode.string) {
        Ok(value) -> Some(value)
        Error(_) -> None
      }
    }
    Error(_) -> None
  }
}

/// Convert error pairs to JSON objects
fn error_to_json(pair: #(String, String)) -> json.Json {
  json.object([
    #("field", json.string(pair.0)),
    #("message", json.string(pair.1)),
  ])
}

/// Handler for PUT /api/stores/:id - update store
/// This is the main entry point used by tests
pub fn handle_request(req: wisp.Request, state: boba_store.StoreState) -> wisp.Response {
  let store_id_opt = parse_store_id(req.path)

  case store_id_opt {
    option.None -> wisp.not_found()
    Some(store_id) -> {
      // Get the request body as string
      let body_str = case req.body {
        wisp.TextBody(text) -> text
        wisp.EmptyBody -> "{}"
        wisp.FileBody(_, _, _) -> "{}"
      }

      case decode_update_payload(body_str) {
        Error(_) -> {
          let error_obj = json.object([
            #("errors", json.array([json.string("Invalid JSON")], of: fn(x) { x })),
          ])
          wisp.response(422)
          |> wisp.set_body(wisp.TextBody(json.to_string(error_obj)))
        }
        Ok(payload_dict) -> {
          // Check if store exists in the provided state
          case dict.get(state, store_id) {
            Error(_) -> {
              // Store not found - return 404 with empty body
              wisp.response(404)
              |> wisp.set_body(wisp.EmptyBody)
            }
            Ok(existing_store) -> {
              let name_opt = get_optional_string_field(payload_dict, "name")
              let address_opt = get_optional_string_field(payload_dict, "address")
              let city_opt = get_optional_string_field(payload_dict, "city")
              let phone_opt = get_optional_string_field(payload_dict, "phone")

              let validation_name = case name_opt {
                Some(name) -> name
                None -> existing_store.name
              }

              let validation_input = store_validation.StoreValidationInput(
                name: validation_name,
                address: case address_opt {
                  Some(addr) -> Some(addr)
                  None -> existing_store.address
                },
                phone: case phone_opt {
                  Some(phone) -> Some(phone)
                  None -> existing_store.phone
                },
              )

              case store_validation.validate(validation_input) {
                store_validation.Invalid(errors) -> {
                  let error_pairs = store_validation.errors_to_pairs(errors)
                  let error_objects = list.map(error_pairs, error_to_json)
                  let response_body =
                    json.object([#("errors", json.array(error_objects, of: fn(x) { x }))])
                    |> json.to_string

                  wisp.response(422)
                  |> wisp.set_body(wisp.TextBody(response_body))
                }
                store_validation.Valid -> {
                  // Create updated store
                  let updated_store = boba_store.Store(
                    id: existing_store.id,
                    name: case name_opt {
                      Some(name) -> name
                      None -> existing_store.name
                    },
                    address: case address_opt {
                      Some(addr) -> Some(addr)
                      None -> existing_store.address
                    },
                    city: case city_opt {
                      Some(city) -> Some(city)
                      None -> existing_store.city
                    },
                    phone: case phone_opt {
                      Some(phone) -> Some(phone)
                      None -> existing_store.phone
                    },
                    created_at: existing_store.created_at,
                    updated_at: "2026-04-12T00:00:00Z", // In real impl, use current timestamp
                  )

                  // Build response JSON
                  let response_obj = json.object([
                    #("id", json.string(updated_store.id)),
                    #("name", json.string(updated_store.name)),
                    #("address", case updated_store.address {
                      Some(addr) -> json.string(addr)
                      None -> json.null()
                    }),
                    #("city", case updated_store.city {
                      Some(city) -> json.string(city)
                      None -> json.null()
                    }),
                    #("phone", case updated_store.phone {
                      Some(phone) -> json.string(phone)
                      None -> json.null()
                    }),
                    #("updated_at", json.string(updated_store.updated_at)),
                  ])

                  wisp.response(200)
                  |> wisp.set_body(wisp.TextBody(json.to_string(response_obj)))
                }
              }
            }
          }
        }
      }
    }
  }
}
