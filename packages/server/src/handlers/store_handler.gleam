/// Store HTTP handlers - merged from unit-4 and unit-5

import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/string
import services/auth.{extract_user, user_id}
import services/geocoding.{geocode_address}
import services/store_service.{
  type StoreMsg,
  create_store,
  get_store as get_store_from_service,
}
import shared.{
  store_to_json,
  decode_create_store_request,
  InvalidInput,
  Conflict,
  InternalError,
  Unauthorized,
  error_to_json,
}
import web/server.{type Request, type Response, json_response}

/// Handle POST /api/stores - Create a new store
pub fn create(
  request: Request,
  store_actor: Subject(StoreMsg),
) -> Response {
  // Extract user from headers
  let user_result = extract_user(request.headers)

  case user_result {
    Error(msg) -> {
      json_response(
        401,
        error_to_json(Unauthorized(msg)) |> json.to_string,
      )
    }
    Ok(user_ctx) -> {
      // Parse request body
      case decode_create_store_request(request.body) {
        Error(msg) -> {
          json_response(
            422,
            error_to_json(InvalidInput(msg)) |> json.to_string,
          )
        }
        Ok(create_request) -> {
          // Geocode the address
          case geocode_address(create_request.address) {
            Error(msg) -> {
              json_response(
                422,
                error_to_json(InvalidInput("Failed to geocode address: " <> msg))
                  |> json.to_string,
              )
            }
            Ok(coords) -> {
              // Create the store
              case create_store(
                store_actor,
                create_request,
                coords,
                user_id(user_ctx),
              ) {
                Error(msg) -> {
                  // Check if it's a conflict error
                  let status = case string.contains(msg, "already exists") {
                    True -> 409
                    False -> 500
                  }
                  let error_type = case status {
                    409 -> Conflict(msg)
                    _ -> InternalError(msg)
                  }
                  json_response(
                    status,
                    error_to_json(error_type) |> json.to_string,
                  )
                }
                Ok(store) -> {
                  json_response(
                    201,
                    store_to_json(store) |> json.to_string,
                  )
                }
              }
            }
          }
        }
      }
    }
  }
}

/// Handle GET /api/stores/:id - Get store by ID
pub fn get_store(
  _request: Request,
  store_actor: Subject(StoreMsg),
  store_id: String,
) -> Response {
  case get_store_from_service(store_actor, store_id) {
    Ok(store) -> {
      // Return the store data
      let body = store_to_json(store) |> json.to_string
      json_response(200, body)
    }
    Error(_) -> {
      let body =
        json.object([#("error", json.string("Store not found"))])
        |> json.to_string
      json_response(404, body)
    }
  }
}
