import gleam/json
import gleam/string
import handlers/rating_handler
import store/rating_store.{type RatingStore}
import web/server.{type Request, type Response}
import web/static

pub fn make_handler(store: RatingStore) -> fn(Request) -> Response {
  fn(request: Request) { route(request, store) }
}

fn route(request: Request, store: RatingStore) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "DELETE", path -> route_delete(path, request, store)
    "GET", path -> route_get(path)
    _, _ -> not_found()
  }
}

fn route_get(path: String) -> Response {
  case string.starts_with(path, "/static/") {
    True -> static.serve(path)
    False -> not_found()
  }
}

fn route_delete(path: String, request: Request, store: RatingStore) -> Response {
  // Match DELETE /api/ratings/store/:rating_id
  case parse_rating_delete_path(path) {
    Ok(rating_id) -> rating_handler.delete_store_rating(store, request, rating_id)
    Error(Nil) -> not_found()
  }
}

fn parse_rating_delete_path(path: String) -> Result(String, Nil) {
  // Parse /api/ratings/store/:rating_id pattern
  case string.split(path, "/") {
    ["", "api", "ratings", "store", rating_id] -> Ok(rating_id)
    _ -> Error(Nil)
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
