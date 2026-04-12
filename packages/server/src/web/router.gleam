import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import shared.{type Todo}
import web/server.{type Request, type Response}
import web/static

pub type ListTodosFn =
  fn(String) -> Result(List(Todo), String)

pub fn make_handler(list_todos: ListTodosFn) -> fn(Request) -> Response {
  fn(request: Request) { route(request, list_todos) }
}

fn route(request: Request, list_todos: ListTodosFn) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "GET", "/api/todos" -> list_todos_handler(request, list_todos)
    "GET", path -> route_get(path)
    _, _ -> not_found()
  }
}

fn list_todos_handler(request: Request, list_todos: ListTodosFn) -> Response {
  let filter = extract_query_param(request.path, "filter")
  |> option.unwrap("all")

  case list_todos(filter) {
    Ok(todos) -> {
      let todos_json = json.array(todos, todo_to_json)
      let body = json.object([#("todos", todos_json)])
      |> json.to_string
      server.json_response(200, body)
    }
    Error(_) -> {
      server.json_response(500, json.object([#("error", json.string("Failed to list todos"))]) |> json.to_string)
    }
  }
}

fn todo_to_json(item: Todo) -> json.Json {
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
  ])
}

fn extract_query_param(path: String, key: String) -> option.Option(String) {
  case string.split(path, "?") {
    [_, query_string] -> {
      let pairs = string.split(query_string, "&")
      list.find(pairs, fn(pair) {
        case string.split(pair, "=") {
          [k, _] if k == key -> True
          _ -> False
        }
      })
      |> fn(result) {
        case result {
          Ok(pair) -> {
            case string.split(pair, "=") {
              [_, value] -> Some(value)
              _ -> None
            }
          }
          Error(_) -> None
        }
      }
    }
    _ -> None
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
