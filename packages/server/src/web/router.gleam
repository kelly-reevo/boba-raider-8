import gleam/json
import gleam/string
import store/ratings_store.{type RatingsStore}
import web/handlers/ratings
import web/server.{type Request, type Response}
import web/static

pub fn make_handler(store: RatingsStore) -> fn(Request) -> Response {
  fn(request: Request) { route(request, store) }
}

fn route(request: Request, store: RatingsStore) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "GET", path -> route_get(path, request, store)
    _, _ -> not_found()
  }
}

fn route_get(path: String, request: Request, store: RatingsStore) -> Response {
  // Strip query string for path matching
  let path_without_query = case string.split(path, "?") {
    [base, _] -> base
    _ -> path
  }

  case string.starts_with(path_without_query, "/static/") {
    True -> static.serve(path)
    False -> {
      // Check for API routes
      case match_drink_ratings(path_without_query) {
        Ok(drink_id) -> ratings.list_by_drink(store, request, drink_id)
        Error(Nil) -> not_found()
      }
    }
  }
}

/// Match /api/drinks/:drink_id/ratings pattern
fn match_drink_ratings(path: String) -> Result(String, Nil) {
  // Simple path parsing - extract drink_id from /api/drinks/{id}/ratings
  case string.starts_with(path, "/api/drinks/") && string.ends_with(path, "/ratings") {
    True -> {
      // Remove "/api/drinks/" prefix (12 chars)
      let prefix_len = 12
      // Remove "/ratings" suffix (8 chars)
      let suffix_len = 8
      let total_len = string.length(path)
      let drink_id_len = total_len - prefix_len - suffix_len

      case drink_id_len > 0 {
        True -> {
          let drink_id = string.slice(path, prefix_len, drink_id_len)
          Ok(drink_id)
        }
        False -> Error(Nil)
      }
    }
    False -> Error(Nil)
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
