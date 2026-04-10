import gleam/json
import gleam/string
import rating_store.{type RatingStore}
import web/rating_handler
import web/server.{type Request, type Response}
import web/static

/// Router state containing store references
pub type RouterState {
  RouterState(rating_store: RatingStore)
}

/// Create request handler with state
pub fn make_handler(state: RouterState) -> fn(Request) -> Response {
  fn(request: Request) { route(request, state) }
}

fn route(request: Request, state: RouterState) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "POST", path -> route_post(path, request, state)
    "GET", path -> route_get(path)
    _, _ -> not_found()
  }
}

fn route_post(path: String, request: Request, state: RouterState) -> Response {
  // Check for rating endpoints
  case string.starts_with(path, "/api/drinks/")
    && string.ends_with(path, "/ratings") {
    True -> rating_handler.create_rating(request, state.rating_store)
    False -> not_found()
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
    json.object([#("status", json.string("ok"))]) |> json.to_string,
  )
}

fn not_found() -> Response {
  server.json_response(
    404,
    json.object([#("error", json.string("Not found"))]) |> json.to_string,
  )
}
