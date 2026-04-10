import data/drink_store.{type StoreMessage}
import gleam/erlang/process.{type Subject}
import gleam/json
import gleam/string
import web/handlers/drink_handler
import web/server.{type Request, type Response, json_response}
import web/static

pub fn make_handler(drink_store: Subject(StoreMessage)) -> fn(Request) -> Response {
  fn(request: Request) { route(request, drink_store) }
}

fn route(request: Request, drink_store: Subject(StoreMessage)) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "POST", path -> route_post(path, request, drink_store)
    "GET", path -> route_get(path)
    _, _ -> not_found()
  }
}

fn route_post(
  path: String,
  request: Request,
  drink_store: Subject(StoreMessage),
) -> Response {
  // Check for drink routes: /api/stores/:store_id/drinks
  case string.starts_with(path, "/api/stores/")
    && string.ends_with(path, "/drinks") {
    True -> drink_handler.create(request, drink_store)
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
  json_response(
    200,
    json.object([#("status", json.string("ok"))])
    |> json.to_string,
  )
}

fn not_found() -> Response {
  json_response(
    404,
    json.object([#("error", json.string("Not found"))])
    |> json.to_string,
  )
}
