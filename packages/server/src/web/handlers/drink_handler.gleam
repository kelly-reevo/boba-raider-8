/// Drink HTTP handlers

import auth/authorization
import domain/drink.{type DrinkId}
import domain/user.{type User, User, Admin, Regular}
import gleam/dict
import gleam/json
import gleam/option.{None, Some}
import storage/store.{type Store}
import web/server.{type Request, type Response, json_response}

/// Extract user from request (simplified - in production, verify JWT/session)
fn extract_user(request: Request) -> User {
  // Simplified: extract user ID from header
  // In production: verify JWT token, session cookie, etc.
  let user_id =
    case dict.get(request.headers, "x-user-id") {
      Ok(id) -> id
      Error(_) -> "anonymous"
    }

  let role =
    case dict.get(request.headers, "x-user-role") {
      Ok("admin") -> Admin
      _ -> Regular
    }

  User(id: user_id, role: role)
}

/// DELETE /api/drinks/:id
/// Returns: 204 No Content on success
///          403 Forbidden if user lacks permission
///          404 Not Found if drink doesn't exist
pub fn delete(store: Store, request: Request, drink_id: DrinkId) -> Response {
  let user = extract_user(request)

  // Check if drink exists
  case store.get_drink(store, drink_id) {
    None ->
      json_response(
        404,
        json.object([#("error", json.string("Drink not found"))])
        |> json.to_string(),
      )

    Some(drink) -> {
      // Check authorization
      case authorization.can_delete_drink(store, user, drink) {
        False ->
          json_response(
            403,
            json.object([#("error", json.string("Forbidden"))])
            |> json.to_string(),
          )

        True -> {
          // Delete drink (cascades to ratings in storage layer)
          let _new_store = store.delete_drink(store, drink_id)

          // Return 204 No Content on success
          server.Response(status: 204, headers: dict.new(), body: "")
        }
      }
    }
  }
}
