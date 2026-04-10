import gleam/json
import gleam/string
import web/server.{type Request, type Response}
import web/static
import web/controller/drink_controller
import web/service/drink_service

pub fn make_handler() -> fn(Request) -> Response {
  // Initialize drink store (in production, would use persistent storage)
  let drink_store = drink_service.new_store()

  fn(request: Request) { route(request, drink_store) }
}

fn route(request: Request, drink_store: drink_service.DrinkStore) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "GET", "/api/drinks/" <> id -> drink_controller.get_drink(drink_store, id)
    "PATCH", "/api/drinks/" <> id -> drink_controller.patch_drink(drink_store, request, id)
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
