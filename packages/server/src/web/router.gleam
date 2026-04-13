import boba_store.{type AggregateRatings, type BobaStore}
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/string
import web/server.{type Request, type Response}
import web/static

pub fn make_handler(store: BobaStore) -> fn(Request) -> Response {
  fn(request: Request) { route(request, store) }
}

fn route(request: Request, store: BobaStore) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "GET", path -> route_get(path, store)
    _, _ -> not_found()
  }
}

fn route_get(path: String, store: BobaStore) -> Response {
  // Check for drink aggregates endpoint: /api/drinks/:id/aggregates
  case string.starts_with(path, "/api/drinks/") && string.ends_with(path, "/aggregates") {
    True -> {
      // Extract drink_id from /api/drinks/{id}/aggregates
      // Format: /api/drinks/{uuid}/aggregates
      let prefix_len = string.length("/api/drinks/")
      let suffix_len = string.length("/aggregates")
      let total_len = string.length(path)
      // drink_id is between prefix and suffix
      let drink_id_len = total_len - prefix_len - suffix_len
      let drink_id = string.slice(from: path, at_index: prefix_len, length: drink_id_len)
      get_drink_aggregates_handler(store, drink_id)
    }
    False -> {
      case string.starts_with(path, "/static/") {
        True -> static.serve(path)
        False -> not_found()
      }
    }
  }
}

fn get_drink_aggregates_handler(store: BobaStore, drink_id: String) -> Response {
  case boba_store.get_drink_aggregates(store, drink_id) {
    Error("Drink not found") -> not_found()
    Error(err) -> {
      server.json_response(
        500,
        json.object([#("error", json.string(err))])
        |> json.to_string,
      )
    }
    Ok(aggregates) -> {
      server.json_response(
        200,
        encode_aggregate_ratings(aggregates)
        |> json.to_string,
      )
    }
  }
}

fn encode_aggregate_ratings(aggregates: AggregateRatings) -> json.Json {
  json.object([
    #("drink_id", json.string(aggregates.drink_id)),
    #("overall_rating", encode_optional_float(aggregates.overall_rating)),
    #("sweetness", encode_optional_float(aggregates.sweetness)),
    #("boba_texture", encode_optional_float(aggregates.boba_texture)),
    #("tea_strength", encode_optional_float(aggregates.tea_strength)),
    #("count", json.int(aggregates.count)),
  ])
}

fn encode_optional_float(value: Option(Float)) -> json.Json {
  case value {
    Some(f) -> json.float(f)
    None -> json.null()
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
