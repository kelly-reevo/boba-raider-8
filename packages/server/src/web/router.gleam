import data/drink_store.{type StoreMessage}
import gleam/erlang/process.{type Subject}
import gleam/json
import gleam/option
import gleam/string
import web/handlers/drink_handler
import web/server.{type Request, type Response, json_response}
import web/static
import db/drink_store
import db/store_actor.{type StoreActor}
import domain/drink

/// Create handler without store (for backward compatibility)
pub fn make_handler() -> fn(Request) -> Response {
  fn(request: Request) { route(request, option.None) }
}

/// Create handler with store access
pub fn make_handler_with_store(store: StoreActor) -> fn(Request) -> Response {
  fn(request: Request) { route(request, option.Some(store)) }
}

fn route(request: Request, maybe_store: option.Option(StoreActor)) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "GET", "/api/drinks/" <> id -> get_drink_handler(id, maybe_store)
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

fn get_drink_handler(drink_id: String, maybe_store: option.Option(StoreActor)) -> Response {
  case maybe_store {
    option.None -> not_found()
    option.Some(store) -> {
      let store_state = store_actor.get_state(store)
      case drink_store.get_drink_by_id(store_state, drink_id) {
        option.Some(drink_details) -> {
          let body = drink.encode_drink_with_details(drink_details)
            |> json.to_string
          server.json_response(200, body)
        }
        option.None -> not_found()
      }
    }
  }
}

fn not_found() -> Response {
  json_response(
    404,
    json.object([#("error", json.string("Not found"))])
    |> json.to_string,
  )
}
