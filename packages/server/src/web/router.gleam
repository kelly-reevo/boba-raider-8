import gleam/json
import gleam/string
import store_repo.{type StoreRepo}
import web/server.{type Request, type Response}
import web/static
import web/store_handler

pub fn make_handler(repo: StoreRepo) -> fn(Request) -> Response {
  fn(request: Request) { route(request, repo) }
}

fn route(request: Request, repo: StoreRepo) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "POST", "/api/stores" -> store_handler.handle_create(request, repo)
    "GET", "/api/stores" -> store_handler.handle_list(request, repo)
    method, path -> route_path(method, path, request, repo)
  }
}

fn route_path(
  method: String,
  path: String,
  request: Request,
  repo: StoreRepo,
) -> Response {
  case string.starts_with(path, "/api/stores/") {
    True -> {
      let id = string.drop_start(path, string.length("/api/stores/"))
      case method {
        "GET" -> store_handler.handle_get(request, repo, id)
        "PUT" -> store_handler.handle_update(request, repo, id)
        "DELETE" -> store_handler.handle_delete(request, repo, id)
        _ -> not_found()
      }
    }
    False ->
      case method {
        "GET" -> route_get(path)
        _ -> not_found()
      }
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
