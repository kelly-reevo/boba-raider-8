import gleam/dict
import gleam/erlang/process.{type Subject}
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/string
import shared.{Admin, Creator, NotFound, Regular}
import store/store_actor.{type StoreMessage}
import web/server.{type Request, type Response, json_response}

// Extract store ID from path like "/api/stores/123"
pub fn extract_store_id(path: String) -> Option(String) {
  let parts = string.split(path, "/")
  case parts {
    ["", "api", "stores", id] -> Some(id)
    _ -> None
  }
}

// Extract user from request headers (simplified auth)
// In production, this would validate a JWT token
fn extract_user_from_request(request: Request) -> Option(#(String, shared.UserRole)) {
  // Check for X-User-Id and X-User-Role headers
  let user_id = dict.get(request.headers, "x-user-id")
  let user_role = dict.get(request.headers, "x-user-role")

  case user_id, user_role {
    Ok(id), Ok(role_str) -> {
      let role = case role_str {
        "admin" -> Admin
        "creator" -> Creator
        _ -> Regular
      }
      Some(#(id, role))
    }
    Ok(id), Error(_) -> Some(#(id, Regular))
    _, _ -> None
  }
}

// Delete store handler - DELETE /api/stores/:id
pub fn delete_store_handler(
  request: Request,
  store_actor_ref: Subject(StoreMessage),
) -> Response {
  // Extract store ID from path
  let store_id_result = extract_store_id(request.path)

  // Extract user from request
  let user_result = extract_user_from_request(request)

  case store_id_result, user_result {
    None, _ -> {
      json_response(
        404,
        json.object([#("error", json.string("Not found"))])
        |> json.to_string,
      )
    }
    _, None -> {
      json_response(
        403,
        json.object([#("error", json.string("Forbidden: authentication required"))])
        |> json.to_string,
      )
    }
    Some(store_id), Some(#(user_id, user_role)) -> {
      // Get store to check ownership
      let store_result = store_actor.get_store(store_actor_ref, store_id)

      case store_result {
        Error(NotFound(_)) -> {
          json_response(
            404,
            json.object([#("error", json.string("Store not found"))])
            |> json.to_string,
          )
        }
        Error(_) -> {
          json_response(
            500,
            json.object([#("error", json.string("Internal error"))])
            |> json.to_string,
          )
        }
        Ok(store) -> {
          // Check authorization: only creator or admin can delete
          let is_authorized = case user_role {
            Admin -> True
            _ -> store.creator_id == user_id
          }

          case is_authorized {
            False -> {
              json_response(
                403,
                json.object([#("error", json.string("Forbidden: only creator or admin can delete"))])
                |> json.to_string,
              )
            }
            True -> {
              // Perform deletion with cascade
              let delete_result = store_actor.delete_store(store_actor_ref, store_id)

              case delete_result {
                Ok(_) -> {
                  // Return 204 No Content on successful deletion
                  json_response(204, "")
                }
                Error(NotFound(_)) -> {
                  json_response(
                    404,
                    json.object([#("error", json.string("Store not found"))])
                    |> json.to_string,
                  )
                }
                Error(_) -> {
                  json_response(
                    500,
                    json.object([#("error", json.string("Internal error during deletion"))])
                    |> json.to_string,
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
