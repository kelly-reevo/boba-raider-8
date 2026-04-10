/// HTTP handlers for store endpoints

import gleam/erlang/process.{type Subject}
import gleam/json
import gleam/string
import shared.{type Store, type StoreUpdate, type AppError, type Option, StoreUpdate, Some, None, NotFound, store_to_json}
import store/store_data.{type StoreMsg, GetStore, UpdateStore}
import web/auth
import web/server.{type Request, type Response, json_response}

/// Handle PATCH /api/stores/:id - update store details
pub fn update_store(
  request: Request,
  store_actor: Subject(StoreMsg),
) -> Response {
  // Extract store ID from path
  let store_id = case string.split(request.path, "/") {
    [_, _, _, id] -> id
    _ -> ""
  }

  // Parse request body
  let update_result = parse_update_body(request.body)

  case update_result {
    Error(msg) -> json_response(422, error_json(msg))
    Ok(update) -> {
      // Get current user from headers
      case auth.get_current_user(request.headers) {
        Error(_) -> json_response(403, error_json("Authentication required"))
        Ok(user) -> {
          // Get store to check ownership
          let store_result = get_store(store_actor, store_id)

          case store_result {
            Error(NotFound(_)) -> json_response(404, error_json("Store not found"))
            Error(_) -> json_response(500, error_json("Internal error"))
            Ok(store) -> {
              // Check authorization
              case auth.can_modify_store(user, store.creator_id) {
                False -> json_response(403, error_json("Not authorized to modify this store"))
                True -> {
                  // Perform update
                  case update_store_data(store_actor, store_id, update) {
                    Error(NotFound(_)) -> json_response(404, error_json("Store not found"))
                    Error(_) -> json_response(500, error_json("Update failed"))
                    Ok(updated_store) -> {
                      let body = json.object([
                        #("store", store_to_json(updated_store))
                      ])
                      |> json.to_string

                      json_response(200, body)
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

/// Parse JSON body into StoreUpdate
fn parse_update_body(body: String) -> Result(StoreUpdate, String) {
  // Simplified JSON parsing - in production use proper JSON decoder
  case body {
    "" -> Ok(StoreUpdate(None, None, None, None, None, None))
    _ -> {
      // Extract fields using simple string parsing (for this implementation)
      // Production would use gleam_json decode
      let name = extract_string_field(body, "name")
      let address = extract_string_field(body, "address")
      let phone = extract_string_field(body, "phone")
      let hours = extract_string_field(body, "hours")
      let description = extract_string_field(body, "description")
      let image_url = extract_string_field(body, "image_url")

      Ok(StoreUpdate(name, address, phone, hours, description, image_url))
    }
  }
}

/// Extract string field from JSON body (simplified)
fn extract_string_field(body: String, field: String) -> Option(String) {
  let pattern = "\"" <> field <> "\":\""
  case string.split(body, pattern) {
    [_, rest] -> {
      case string.split(rest, "\"") {
        [value, ..] -> Some(value)
        _ -> None
      }
    }
    _ -> None
  }
}

/// Get store by ID from actor
fn get_store(
  actor: Subject(StoreMsg),
  id: String,
) -> Result(Store, AppError) {
  // Send message and wait for reply
  process.call(
    actor,
    5000,
    fn(reply_to) { GetStore(id, reply_to) },
  )
}

/// Update store via actor
fn update_store_data(
  actor: Subject(StoreMsg),
  id: String,
  update: StoreUpdate,
) -> Result(Store, AppError) {
  process.call(
    actor,
    5000,
    fn(reply_to) { UpdateStore(id, update, reply_to) },
  )
}

/// Error response JSON
fn error_json(message: String) -> String {
  json.object([#("error", json.string(message))])
  |> json.to_string
}
