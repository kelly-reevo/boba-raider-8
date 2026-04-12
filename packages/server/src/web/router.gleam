import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import shared.{type Todo, type UpdateTodoInput}
import todo_store.{type Store}
import web/error_middleware
import web/server.{type Request, type Response, json_response}
import web/static

/// Create the main request handler with error handling middleware
pub fn make_handler(store: Store) -> fn(Request) -> Response {
  let base_handler = fn(request: Request) { route(request, store) }
  error_middleware.with_error_handling(base_handler)
}

fn route(request: Request, store: Store) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "GET", "/api/todos" -> list_todos_handler(store)
    "GET", path -> route_get_todo(path, store)
    "POST", "/api/todos" -> create_todo_handler(request, store)
    "PATCH", path -> route_patch_todo(path, request, store)
    "DELETE", path -> route_delete_todo(path, store)
    _, _ -> not_found()
  }
}

fn route_get(path: String) -> Response {
  case string.starts_with(path, "/static/") {
    True -> static.serve(path)
    False -> not_found()
  }
}

fn route_get_todo(path: String, store: Store) -> Response {
  case string.starts_with(path, "/api/todos/") {
    True -> {
      // Extract ID after "/api/todos/" prefix
      let id = string.slice(path, at_index: 11, length: string.length(path) - 11)
      get_todo_handler(id, store)
    }
    False -> route_get(path)
  }
}

fn route_patch_todo(path: String, request: Request, store: Store) -> Response {
  case string.starts_with(path, "/api/todos/") {
    True -> {
      // Extract ID after "/api/todos/" prefix
      let id = string.slice(path, at_index: 11, length: string.length(path) - 11)
      update_todo_handler(request, id, store)
    }
    False -> not_found()
  }
}

fn route_delete_todo(path: String, store: Store) -> Response {
  case string.starts_with(path, "/api/todos/") {
    True -> {
      // Extract ID after "/api/todos/" prefix
      let id = string.slice(path, at_index: 11, length: string.length(path) - 11)
      delete_todo_handler(id, store)
    }
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

fn list_todos_handler(store: Store) -> Response {
  let todos = todo_store.get_all_todos(store)
  json_response(200, todos_to_json(todos))
}

fn get_todo_handler(id: String, store: Store) -> Response {
  case todo_store.get_todo(store, id) {
    Some(item) -> json_response(200, todo_to_json(item))
    None -> not_found()
  }
}

fn create_todo_handler(request: Request, store: Store) -> Response {
  // Parse request body - JSON validation already done by middleware
  case parse_create_todo_request(request.body) {
    Ok(#(title, description)) -> {
      case string.trim(title) {
        "" -> {
          // Empty title is a validation error
          json_response(
            400,
            json.object([#("error", json.string("Title cannot be empty"))])
            |> json.to_string,
          )
        }
        trimmed -> {
          let desc_opt = case description {
            "" -> None
            d -> Some(d)
          }
          case todo_store.create_todo(store, trimmed, desc_opt) {
            Ok(item) -> json_response(201, todo_to_json(item))
            Error(_) -> {
              json_response(
                500,
                json.object([#("error", json.string("Internal server error"))])
                |> json.to_string,
              )
            }
          }
        }
      }
    }
    Error(_) -> {
      json_response(
        400,
        json.object([#("error", json.string("Invalid request body"))])
        |> json.to_string,
      )
    }
  }
}

fn update_todo_handler(request: Request, id: String, store: Store) -> Response {
  // Parse request body - JSON validation already done by middleware
  case parse_update_todo_request(request.body) {
    Ok(input) -> {
      case todo_store.update_todo(store, id, input) {
        Ok(item) -> json_response(200, todo_to_json(item))
        Error(_) -> not_found()
      }
    }
    Error(_) -> {
      json_response(
        400,
        json.object([#("error", json.string("Invalid request body"))])
        |> json.to_string,
      )
    }
  }
}

fn delete_todo_handler(id: String, store: Store) -> Response {
  case todo_store.delete_todo(store, id) {
    Ok(_) -> json_response(204, "")
    Error(_) -> not_found()
  }
}

fn parse_create_todo_request(body: String) -> Result(#(String, String), Nil) {
  // Parse JSON body to extract title and optional description
  let decoder = {
    use title <- decode.field("title", decode.string)
    use description <- decode.field("description", decode.optional(decode.string))
    decode.success(#(title, option.unwrap(description, "")))
  }

  case json.parse(from: body, using: decoder) {
    Ok(result) -> Ok(result)
    Error(_) -> Error(Nil)
  }
}

fn parse_update_todo_request(body: String) -> Result(UpdateTodoInput, Nil) {
  // Parse JSON body to extract optional title, description, completed
  let decoder = {
    use title <- decode.field("title", decode.optional(decode.string))
    use description <- decode.field("description", decode.optional(decode.string))
    use completed <- decode.field("completed", decode.optional(decode.bool))
    decode.success(shared.UpdateTodoInput(
      title: title,
      description: description,
      completed: completed,
    ))
  }

  case json.parse(from: body, using: decoder) {
    Ok(result) -> Ok(result)
    Error(_) -> Error(Nil)
  }
}

fn todo_to_json(item: Todo) -> String {
  json.object([
    #("id", json.string(item.id)),
    #("title", json.string(item.title)),
    #("description", case item.description {
      Some(d) -> json.string(d)
      None -> json.null()
    }),
    #("priority", json.string(priority_to_string(item.priority))),
    #("completed", json.bool(item.completed)),
    #("created_at", json.string(item.created_at)),
    #("updated_at", json.string(item.updated_at)),
  ])
  |> json.to_string
}

fn todos_to_json(todos: List(Todo)) -> String {
  json.array(todos, fn(item) {
    json.object([
      #("id", json.string(item.id)),
      #("title", json.string(item.title)),
      #("description", case item.description {
        Some(d) -> json.string(d)
        None -> json.null()
      }),
      #("priority", json.string(priority_to_string(item.priority))),
      #("completed", json.bool(item.completed)),
      #("created_at", json.string(item.created_at)),
      #("updated_at", json.string(item.updated_at)),
    ])
  })
  |> json.to_string
}

fn priority_to_string(priority: shared.Priority) -> String {
  case priority {
    shared.Low -> "low"
    shared.Medium -> "medium"
    shared.High -> "high"
  }
}
