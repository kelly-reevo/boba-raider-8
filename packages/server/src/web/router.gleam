import domain/store
import gleam/json
import gleam/string
import shared
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
    "GET", path -> route_get(path)
    _, _ -> not_found()
  }
}

fn route_get(path: String) -> Response {
  // Strip query string for route matching
  let base_path = case string.split(path, "?") {
    [p, _] -> p
    _ -> path
  }

  case base_path {
    "/api/stores" -> stores_handler(path)
    _ -> {
      case string.starts_with(base_path, "/static/") {
        True -> static.serve(base_path)
        False -> not_found()
      }
    }
  }
}

fn health_handler() -> Response {
  server.json_response(
    200,
    json.object([#("status", json.string("ok"))])
    |> json.to_string,
  )
}

fn stores_handler(path: String) -> Response {
  // Extract query string from path (everything after ?)
  let query = case string.split(path, "?") {
    [_, q] -> q
    _ -> ""
  }

  case store.parse_params(query) {
    Ok(params) -> {
      let result = store.list_stores(params)
      server.json_response(
        200,
        store.encode_result(result)
        |> json.to_string,
      )
    }
    Error(error) -> {
      server.json_response(
        400,
        json.object([#("error", json.string(shared.error_message(error)))])
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
