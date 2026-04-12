import gleam/dict
import gleam/json
import gleam/option.{None, Some}
import gleam/string
import todo_store.{type Store, GetOkResult, GetErrorResult, DeleteOkResult, DeleteErrorResult, NotFoundDelete}
import web/server.{type Request, type Response}
import web/static

pub fn make_handler(store: Store) -> fn(Request) -> Response {
  fn(request: Request) { route(request, store) }
}

fn route(request: Request, store: Store) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "DELETE", path -> route_delete(path, store)
    "GET", path -> route_get(path, store)
    _, _ -> not_found()
  }
}

fn route_get(path: String, store: Store) -> Response {
  case string.starts_with(path, "/static/") {
    True -> static.serve(path)
    False -> {
      case string.starts_with(path, "/api/todos/") {
        True -> {
          let id = string.drop_start(path, 11)
          case todo_store.get_api(store, id) {
            GetOkResult(item) -> {
              server.json_response(
                200,
                json.object([
                  #("id", json.string(item.id)),
                  #("title", json.string(item.title)),
                  #("description", case item.description {
                    Some(d) -> json.string(d)
                    None -> json.null()
                  }),
                  #("priority", json.string(item.priority)),
                  #("completed", json.bool(item.completed)),
                  #("created_at", json.int(item.created_at)),
                  #("updated_at", json.int(item.updated_at)),
                ])
                |> json.to_string,
              )
            }
            GetErrorResult(_) -> todo_not_found()
          }
        }
        False -> not_found()
      }
    }
  }
}

fn route_delete(path: String, store: Store) -> Response {
  case string.starts_with(path, "/api/todos/") {
    True -> {
      let id = string.drop_start(path, 11)
      case todo_store.delete_api(store, id) {
        DeleteOkResult -> no_content_response()
        DeleteErrorResult(NotFoundDelete) -> todo_not_found()
      }
    }
    False -> not_found()
  }
}

fn no_content_response() -> Response {
  server.Response(
    status: 204,
    headers: dict.from_list([#("Content-Type", "application/json")]),
    body: "",
  )
}

fn todo_not_found() -> Response {
  server.json_response(
    404,
    json.object([#("error", json.string("Todo not found"))])
    |> json.to_string,
  )
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
