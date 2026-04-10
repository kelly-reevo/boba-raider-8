import gleam/erlang/process.{type Subject}
import gleam/json
import gleam/string
import store/store_data.{type StoreMsg}
import store/store_handler
import web/server.{type Request, type Response}
import web/static

pub fn make_handler(store_actor: Subject(StoreMsg)) -> fn(Request) -> Response {
  fn(request: Request) { route(request, store_actor) }
}

fn route(request: Request, store_actor: Subject(StoreMsg)) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "PATCH", path -> route_patch(path, request, store_actor)
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

fn route_patch(
  path: String,
  request: Request,
  store_actor: Subject(StoreMsg),
) -> Response {
  case string.starts_with(path, "/api/stores/") {
    True -> store_handler.update_store(request, store_actor)
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
