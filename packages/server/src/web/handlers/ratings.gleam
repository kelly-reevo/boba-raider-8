/// Drink ratings API handlers

import gleam/dict
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import shared.{type Rating, type User, type PaginationMeta, parse_pagination}
import store/ratings_store.{type RatingsStore, type PaginatedRatings}
import web/server.{type Request, type Response, json_response}

/// Handle GET /api/drinks/:drink_id/ratings
pub fn list_by_drink(
  store: RatingsStore,
  request: Request,
  drink_id: String,
) -> Response {
  // Parse query parameters
  let query_params = parse_query_string(request.path)
  let page_raw =
    dict.get(query_params, "page")
    |> result.unwrap("1")
  let limit_raw =
    dict.get(query_params, "limit")
    |> result.unwrap("20")

  // Validate and apply defaults
  let #(page, limit) = case parse_pagination(page_raw, limit_raw) {
    Ok(params) -> params
    Error(_) -> #(1, 20)
  }

  // Fetch ratings from store
  case ratings_store.get_by_drink(store, drink_id, page, limit) {
    Ok(result) -> {
      // Check if drink exists (has ratings or we need to verify separately)
      // For simplicity: empty result means either no ratings or non-existent drink
      // Return 200 with empty list for both cases per REST conventions
      let body = encode_paginated_response(result)
      json_response(200, json.to_string(body))
    }

    Error(_) -> {
      json_response(
        500,
        json.to_string(json.object([#("error", json.string("Internal error"))])),
      )
    }
  }
}

/// Encode paginated ratings to JSON
fn encode_paginated_response(result: PaginatedRatings) -> json.Json {
  json.object([
    #("data", json.array(result.ratings, encode_rating)),
    #("meta", encode_meta(result.meta)),
  ])
}

/// Encode a single rating to JSON
fn encode_rating(rating: Rating) -> json.Json {
  json.object([
    #("id", json.string(rating.id)),
    #("user", encode_user(rating.user)),
    #("overall_score", json.int(rating.overall_score)),
    #("sweetness", json.int(rating.sweetness)),
    #("boba_texture", json.int(rating.boba_texture)),
    #("tea_strength", json.int(rating.tea_strength)),
    #(
      "review_text",
      case string.is_empty(rating.review_text) {
        True -> json.null()
        False -> json.string(rating.review_text)
      },
    ),
    #("created_at", json.string(rating.created_at)),
    #("updated_at", json.string(rating.updated_at)),
  ])
}

/// Encode user to JSON
fn encode_user(user: User) -> json.Json {
  json.object([
    #("id", json.string(user.id)),
    #("username", json.string(user.username)),
  ])
}

/// Encode pagination metadata to JSON
fn encode_meta(meta: PaginationMeta) -> json.Json {
  json.object([
    #("total", json.int(meta.total)),
    #("page", json.int(meta.page)),
    #("limit", json.int(meta.limit)),
    #("total_pages", json.int(meta.total_pages)),
  ])
}

/// Simple query string parser
fn parse_query_string(path: String) -> dict.Dict(String, String) {
  case string.split(path, "?") {
    [_, query] -> {
      query
      |> string.split("&")
      |> list.filter(fn(s) { !string.is_empty(s) })
      |> list.fold(dict.new(), fn(acc, pair) {
        case string.split(pair, "=") {
          [key, value] -> dict.insert(acc, key, value)
          [key] -> dict.insert(acc, key, "")
          _ -> acc
        }
      })
    }
    _ -> dict.new()
  }
}
