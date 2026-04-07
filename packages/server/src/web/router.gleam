import gleam/json
import gleam/string
import web/rating_store.{type RatingStore}
import web/ratings
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
    _, path ->
      case string.starts_with(path, "/api/drinks/") {
        True -> route_drinks(request, path, store)
        False ->
          case request.method {
            "GET" -> route_get(path)
            _ -> not_found()
          }
      }
  }
}

fn route_drinks(
  request: Request,
  path: String,
  store: RatingStore,
) -> Response {
  // Parse: /api/drinks/<drink_id>/ratings[/aggregated]
  let segments =
    path
    |> string.drop_start(12)
    |> string.split("/")
  case request.method, segments {
    "POST", [drink_id, "ratings"] -> ratings.submit(request, drink_id, store)
    "GET", [drink_id, "ratings"] -> ratings.get_for_drink(drink_id, store)
    "GET", [drink_id, "ratings", "aggregated"] ->
      ratings.get_aggregated(drink_id, store)
    _, _ -> not_found()
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

fn not_found() -> Response {
  server.json_response(
    404,
    json.object([#("error", json.string("Not found"))])
      |> json.to_string,
  )
}
