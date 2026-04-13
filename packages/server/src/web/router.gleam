import gleam/dict
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import rating_service.{type RatingService}
import web/server.{type Request, type Response}
import web/static

/// Context holds service dependencies for the router
pub type Context {
  Context(rating_service: RatingService)
}

/// Make a handler with services injected via context
pub fn make_handler_with_context(ctx: Context) -> fn(Request) -> Response {
  fn(request: Request) { route(request, ctx) }
}

/// Legacy handler factory - creates a simple handler without external services
pub fn make_handler() -> fn(Request) -> Response {
  fn(request: Request) {
    // For simple routes that don't need services
    case request.method, request.path {
      "GET", "/" -> static.serve_index()
      "GET", "/health" -> health_handler()
      "GET", "/api/health" -> health_handler()
      "GET", path -> {
        case string.starts_with(path, "/static/") {
          True -> static.serve(path)
          False -> not_found()
        }
      }
      _, _ -> not_found()
    }
  }
}

fn route(request: Request, ctx: Context) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "GET", path -> route_get(path, request, ctx)
    _, _ -> not_found()
  }
}

fn route_get(path: String, request: Request, ctx: Context) -> Response {
  case string.starts_with(path, "/static/") {
    True -> static.serve(path)
    False -> {
      // Check for /api/drinks/:id/ratings pattern
      case parse_drink_ratings_path(path) {
        Some(drink_id) -> get_drink_ratings_handler(drink_id, request, ctx)
        None -> not_found()
      }
    }
  }
}

fn health_handler() -> Response {
  server.json_response(
    200,
    json.object([#("status", json.string("ok"))])
    |> json.to_string,
  )
}

fn not_found() -> Response {
  server.json_response(
    404,
    json.object([#("error", json.string("Not found"))])
    |> json.to_string,
  )
}

// Parse /api/drinks/:id/ratings pattern
fn parse_drink_ratings_path(path: String) -> option.Option(String) {
  let parts = string.split(path, "/")
  case parts {
    ["", "api", "drinks", drink_id, "ratings"] -> Some(drink_id)
    _ -> None
  }
}

// Parse query parameters from path (e.g., "?limit=10&offset=5")
fn parse_query_params(path: String) -> dict.Dict(String, String) {
  case string.split(path, "?") {
    [_, query_string] -> {
      query_string
      |> string.split("&")
      |> list.fold(dict.new(), fn(acc, pair) {
        case string.split(pair, "=") {
          [key, value] -> dict.insert(acc, key, value)
          _ -> acc
        }
      })
    }
    _ -> dict.new()
  }
}

// Get integer query param with default
fn get_int_param(params: dict.Dict(String, String), key: String, default: Int) -> Int {
  case dict.get(params, key) {
    Ok(value) -> result.unwrap(int.parse(value), default)
    Error(_) -> default
  }
}

// Handler for GET /api/drinks/:id/ratings
fn get_drink_ratings_handler(drink_id: String, request: Request, ctx: Context) -> Response {
  let params = parse_query_params(request.path)
  let limit = get_int_param(params, "limit", 20)
  let offset = get_int_param(params, "offset", 0)

  case rating_service.list_ratings_by_drink_paginated(ctx.rating_service, drink_id, limit, offset) {
    Ok(result) -> {
      let ratings_json = json.array(result.ratings, fn(rating) {
        json.object([
          #("id", json.string(rating.id)),
          #("overall_rating", json.int(rating.overall_rating)),
          #("sweetness", json.int(rating.sweetness)),
          #("boba_texture", json.int(rating.boba_texture)),
          #("tea_strength", json.int(rating.tea_strength)),
          #("created_at", json.string(int.to_string(rating.created_at))),
        ])
      })

      let response = json.object([
        #("ratings", ratings_json),
        #("total", json.int(result.total)),
        #("limit", json.int(result.limit)),
        #("offset", json.int(result.offset)),
      ])

      server.json_response(200, json.to_string(response))
    }
    Error(_) -> not_found()
  }
}

