import gleam/int
import gleam/json
import gleam/option
import gleam/string
import shared.{type AppError, NotFound, InvalidInput}
import web/rating.{type RatingActor}
import web/server.{type Request, type Response}
import web/static
import web/store.{type StoreActor}
import web/user.{type UserActor}

pub fn make_handler(
  store_actor: StoreActor,
  user_actor: UserActor,
  rating_actor: RatingActor,
) -> fn(Request) -> Response {
  fn(request: Request) { route(request, store_actor, user_actor, rating_actor) }
}

fn route(
  request: Request,
  store_actor: StoreActor,
  user_actor: UserActor,
  rating_actor: RatingActor,
) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "POST", path -> route_post(path, request, store_actor, user_actor, rating_actor)
    "GET", path -> route_get(path)
    _, _ -> not_found()
  }
}

fn route_post(
  path: String,
  request: Request,
  store_actor: StoreActor,
  user_actor: UserActor,
  rating_actor: RatingActor,
) -> Response {
  // Parse /api/stores/:store_id/ratings
  case string.split(path, "/") {
    ["", "api", "stores", store_id, "ratings"] -> {
      create_rating_handler(request, store_actor, user_actor, rating_actor, store_id)
    }
    _ -> not_found()
  }
}

fn create_rating_handler(
  request: Request,
  store_actor: StoreActor,
  user_actor: UserActor,
  rating_actor: RatingActor,
  store_id: String,
) -> Response {
  // First verify store exists
  case store.store_exists(store_actor, store_id) {
    False -> not_found()
    True -> {
      // Parse request body
      case parse_create_rating_request(request.body) {
        Error(err) -> unprocessable_entity(err)
        Ok(req) -> {
          // Validate overall_score is 1-5
          case shared.validate_overall_score(req.overall_score) {
            Error(err) -> unprocessable_entity(err)
            Ok(_) -> {
              // For now, get a default user (in production, extract from auth context)
              case user.get_user(user_actor, "user_1") {
                Error(NotFound(_)) -> unprocessable_entity(InvalidInput("User not found"))
                Error(_) -> server_error()
                Ok(user) -> {
                  // Create or update rating
                  case rating.create_rating(
                    rating_actor,
                    store_id,
                    user.id,
                    req.overall_score,
                    req.review_text,
                  ) {
                    Error(_) -> server_error()
                    Ok(_) -> {
                      // Fetch with user for response
                      case rating.get_rating_with_user(
                        rating_actor,
                        user_actor,
                        store_id,
                        user.id,
                      ) {
                        Error(_) -> server_error()
                        Ok(rating_with_user) -> {
                          created(rating_with_user)
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
  }
}

/// Simple string-based JSON parsing for the rating request
/// Expected format: {"overall_score": 5, "review_text": "Great store!"}
fn parse_create_rating_request(body: String) -> Result(shared.CreateRatingRequest, AppError) {
  case body {
    "" -> Error(InvalidInput("Request body is empty"))
    _ -> {
      // Remove whitespace and normalize
      let normalized = body
        |> string.replace(" ", "")
        |> string.replace("\n", "")
        |> string.replace("\t", "")

      // Extract overall_score
      let score_result = extract_json_int_field(normalized, "overall_score")

      // Extract optional review_text
      let text_result = extract_json_string_field(normalized, "review_text")

      case score_result {
        Ok(score) -> Ok(shared.CreateRatingRequest(overall_score: score, review_text: text_result))
        Error(_) -> Error(InvalidInput("overall_score must be an integer between 1 and 5"))
      }
    }
  }
}

/// Extract an integer field from JSON string
fn extract_json_int_field(json: String, field_name: String) -> Result(Int, Nil) {
  let search = "\"" <> field_name <> "\":"
  case string.split(json, search) {
    [_, rest] -> {
      case string.split(rest, ",") {
        [val_str, ..] -> {
          case string.split(val_str, "}") {
            [val_str2, ..] -> int.parse(string.trim(val_str2))
            _ -> int.parse(string.trim(val_str))
          }
        }
        _ -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

/// Extract an optional string field from JSON string
fn extract_json_string_field(json: String, field_name: String) -> option.Option(String) {
  let search = "\"" <> field_name <> "\":\""
  case string.split(json, search) {
    [_, rest] -> {
      case string.split(rest, "\"") {
        [val, ..] -> option.Some(val)
        _ -> option.None
      }
    }
    _ -> {
      // Check for null
      let null_search = "\"" <> field_name <> "\":null"
      case string.contains(json, null_search) {
        True -> option.None
        False -> option.None
      }
    }
  }
}

fn route_get(path: String) -> Response {
  case string.starts_with(path, "/static/") {
    True -> static.serve(path)
    False -> not_found()
  }
}

fn health_handler() -> Response {
  server.json_response(
    200,
    json.object([#("status", json.string("ok"))])
    |> json.to_string,
  )
}

fn created(rating_with_user: shared.RatingWithUser) -> Response {
  let json_body = shared.rating_with_user_to_json(rating_with_user)
    |> json.to_string
  server.json_response(201, json_body)
}

fn not_found() -> Response {
  server.json_response(
    404,
    json.object([#("error", json.string("Not found"))])
    |> json.to_string,
  )
}

fn unprocessable_entity(error: AppError) -> Response {
  let msg = shared.error_message(error)
  server.json_response(
    422,
    json.object([#("error", json.string(msg))])
    |> json.to_string,
  )
}

fn server_error() -> Response {
  server.json_response(
    500,
    json.object([#("error", json.string("Internal server error"))])
    |> json.to_string,
  )
}
