import gleam/json
import gleam/string
import store/ratings_store.{type RatingsTable}
import web/ratings_handler
import web/server.{type Request, type Response}
import web/static

pub fn make_handler(table: RatingsTable) -> fn(Request) -> Response {
  fn(request: Request) { route(request, table) }
}

fn route(request: Request, table: RatingsTable) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "DELETE", path -> route_delete(path, request, table)
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

fn route_delete(path: String, request: Request, table: RatingsTable) -> Response {
  case string.starts_with(path, "/api/ratings/drink/") {
    True -> ratings_handler.delete_rating(request, table)
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
