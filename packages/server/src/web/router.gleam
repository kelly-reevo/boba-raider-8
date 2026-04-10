import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/string
import handlers/store_handler
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
  // API routes take precedence
  case extract_store_id(path) {
    Some(store_id) -> store_handler.get_store(request, store_id)
    None -> {
      // Static file serving
      case string.starts_with(path, "/static/") {
        True -> static.serve(path)
        False -> not_found()
      }
    }
  }
}

/// Extract store ID from /api/stores/:id pattern
fn extract_store_id(path: String) -> Option(String) {
  case string.starts_with(path, "/api/stores/") {
    True -> {
      // Extract ID by slicing after "/api/stores/" (12 characters)
      let prefix_length = 12
      let id = case string.length(path) > prefix_length {
        True -> string.slice(path, prefix_length, string.length(path) - prefix_length)
        False -> ""
      }
      // Ensure ID is not empty and doesn't contain additional path segments
      case id, string.contains(id, "/") {
        "", _ -> None
        _, True -> None
        _, False -> Some(id)
      }
    }
    False -> None
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
