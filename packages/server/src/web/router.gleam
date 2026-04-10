import gleam/json
import gleam/string
import web/handlers/store_handlers
import web/server.{type Request, type Response}
import web/static

pub fn make_handler() -> fn(Request) -> Response {
  fn(request: Request) { route(request) }
}

fn route(request: Request) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "GET", path -> route_get(request, path)
    _, _ -> not_found()
  }
}

fn route_get(request: Request, path: String) -> Response {
  case string.starts_with(path, "/static/") {
    True -> static.serve(path)
    False -> route_api_get(request, path)
  }
}

fn route_api_get(request: Request, path: String) -> Response {
  // Check for /api/stores/:store_id/drinks pattern
  case string.starts_with(path, "/api/stores/")
    && string.ends_with(path, "/drinks") {
    True -> store_handlers.list_drinks_handler(request)
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
