import auth/user_store.{type UserStore}
import gleam/json
import gleam/string
import web/auth_handlers
import web/server.{type Request, type Response}
import web/static

pub fn make_handler(
  store: UserStore,
  jwt_secret: String,
) -> fn(Request) -> Response {
  fn(request: Request) { route(request, store, jwt_secret) }
}

fn route(
  request: Request,
  store: UserStore,
  jwt_secret: String,
) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "POST", "/api/auth/register" ->
      auth_handlers.handle_register(request, store, jwt_secret)
    "POST", "/api/auth/login" ->
      auth_handlers.handle_login(request, store, jwt_secret)
    "GET", "/api/auth/me" ->
      auth_handlers.handle_me(request, store, jwt_secret)
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
