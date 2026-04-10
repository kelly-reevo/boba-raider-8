import gleam/erlang/process.{type Subject}
import gleam/json
import gleam/string
import users.{type UserStoreMsg, RegisterSuccess, RegisterValidationError, RegisterConflict}
import web/server.{type Request, type Response}
import web/static

pub fn make_handler(store: Subject(UserStoreMsg)) -> fn(Request) -> Response {
  fn(request: Request) { route(request, store) }
}

fn route(request: Request, store: Subject(UserStoreMsg)) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "POST", "/api/auth/register" -> register_handler(request, store)
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

fn register_handler(request: Request, store: Subject(UserStoreMsg)) -> Response {
  case users.parse_register_request(request.body) {
    Ok(req) -> {
      case users.register(store, req) {
        RegisterSuccess(user) -> {
          server.json_response(
            201,
            users.user_to_json(user)
            |> json.to_string,
          )
        }
        RegisterValidationError(errors) -> {
          server.json_response(
            422,
            users.errors_to_json(errors)
            |> json.to_string,
          )
        }
        RegisterConflict(msg) -> {
          server.json_response(
            409,
            json.object([#("error", json.string(msg))])
            |> json.to_string,
          )
        }
      }
    }
    Error(msg) -> {
      server.json_response(
        422,
        json.object([
          #("errors", json.array(
            [json.object([#("field", json.string("")), #("message", json.string(msg))])],
            fn(x) { x },
          )),
        ])
        |> json.to_string,
      )
    }
  }
}

fn not_found() -> Response {
  server.json_response(
    404,
    json.object([#("error", json.string("Not found"))])
    |> json.to_string,
  )
}
