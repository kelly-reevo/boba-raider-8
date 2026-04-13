import gleam/dict
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/string
import todo_store.{
  type Store,
  CreateOkResult,
  CreateErrorResult,
  ValidationErrorCreate,
  GetOkResult,
  GetErrorResult,
  NotFoundGet,
  UpdateOkResult,
  UpdateErrorResult,
  NotFoundUpdate,
  ValidationErrorUpdate,
  DeleteOkResult,
  DeleteErrorResult,
  NotFoundDelete,
}
import web/server.{type Request, type Response}
import web/static

pub fn make_handler(store: Store) -> fn(Request) -> Response {
  fn(request: Request) { handle_request(request, store) }
}

fn handle_request(request: Request, store: Store) -> Response {
  // Add CORS headers to all responses
  add_cors_headers(route(request, store))
}

fn route(request: Request, store: Store) -> Response {
  case request.method, request.path {
    // Health check
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()

    // Static files
    "GET", "/" -> static.serve_index()

    // CORS preflight for API routes
    "OPTIONS", "/api/todos" -> cors_preflight_response()
    "OPTIONS", path -> route_options_preflight(path)

    // Todo API routes - exact matches
    "GET", "/api/todos" -> list_todos_handler(store, request)
    "POST", "/api/todos" -> create_todo_handler(store, request)

    // Todo API routes - with ID
    "GET", path -> route_get_with_id(path, store)
    "PATCH", path -> route_patch_with_id(path, store, request)
    "DELETE", path -> route_delete_with_id(path, store)

    // 404 for everything else
    _, _ -> not_found_response()
  }
}

fn route_get_with_id(path: String, store: Store) -> Response {
  case string.starts_with(path, "/static/") {
    True -> static.serve(path)
    False -> {
      case string.starts_with(path, "/api/todos/") {
        True -> {
          let id = string.drop_start(path, 11)
          get_todo_handler(store, id)
        }
        False -> not_found_response()
      }
    }
  }
}

fn route_patch_with_id(path: String, store: Store, request: Request) -> Response {
  case string.starts_with(path, "/api/todos/") {
    True -> {
      let id = string.drop_start(path, 11)
      update_todo_handler(store, id, request)
    }
    False -> not_found_response()
  }
}

fn route_delete_with_id(path: String, store: Store) -> Response {
  case string.starts_with(path, "/api/todos/") {
    True -> {
      let id = string.drop_start(path, 11)
      delete_todo_handler(store, id)
    }
    False -> not_found_response()
  }
}

fn route_options_preflight(path: String) -> Response {
  case string.starts_with(path, "/api/") {
    True -> cors_preflight_response()
    False -> not_found_response()
  }
}

// ============================================
// CORS Middleware
// ============================================

fn add_cors_headers(response: Response) -> Response {
  let new_headers =
    response.headers
    |> dict.insert("Access-Control-Allow-Origin", "*")
    |> dict.insert("Access-Control-Allow-Methods", "GET, POST, PATCH, DELETE")
    |> dict.insert("Access-Control-Allow-Headers", "Content-Type")

  server.Response(..response, headers: new_headers)
}

fn cors_preflight_response() -> Response {
  server.json_response(204, "")
}

// ============================================
// Error Response Builders
// ============================================

fn not_found_response() -> Response {
  let body =
    json.object([#("error", json.string("Not found"))])
    |> json.to_string()

  server.json_response(404, body)
}

fn todo_not_found() -> Response {
  server.json_response(
    404,
    json.object([#("error", json.string("Todo not found"))])
    |> json.to_string(),
  )
}

fn no_content_response() -> Response {
  server.Response(
    status: 204,
    headers: dict.from_list([#("Content-Type", "application/json")]),
    body: "",
  )
}

fn validation_error_response(errors: List(FieldError)) -> Response {
  let error_items =
    list.map(errors, fn(e) {
      json.object([
        #("field", json.string(e.field)),
        #("message", json.string(e.message)),
      ])
    })

  let body =
    json.object([#("errors", json.array(error_items, fn(x) { x }))])
    |> json.to_string()

  server.json_response(422, body)
}

fn bad_request_response(message: String) -> Response {
  let body =
    json.object([#("error", json.string(message))])
    |> json.to_string()

  server.json_response(400, body)
}

// ============================================
// Handlers
// ============================================

fn health_handler() -> Response {
  server.json_response(
    200,
    json.object([#("status", json.string("ok"))]) |> json.to_string(),
  )
}

fn list_todos_handler(store: Store, request: Request) -> Response {
  let filter = extract_query_param(request.path, "filter")
    |> option.unwrap("all")

  case todo_store.list_all(store, filter) {
    Ok(todos) -> {
      let todo_jsons = list.map(todos, todo_to_json)
      let body = json.array(todo_jsons, fn(x) { x }) |> json.to_string()
      server.json_response(200, body)
    }
    Error(_) -> {
      server.json_response(500, json.object([#("error", json.string("Failed to list todos"))]) |> json.to_string())
    }
  }
}

fn extract_query_param(path: String, key: String) -> Option(String) {
  case string.split(path, "?") {
    [_, query_string] -> {
      let pairs = string.split(query_string, "&")
      case list.find(pairs, fn(pair) {
        case string.split(pair, "=") {
          [k, _] if k == key -> True
          _ -> False
        }
      }) {
        Ok(pair) -> {
          case string.split(pair, "=") {
            [_, value] -> Some(value)
            _ -> None
          }
        }
        Error(_) -> None
      }
    }
    _ -> None
  }
}

fn create_todo_handler(store: Store, request: Request) -> Response {
  // Parse JSON payload
  let result = parse_json_payload(request.body)
  case result {
    Ok(payload) -> {
      case todo_store.create_api(store, payload) {
        CreateOkResult(item) -> {
          let body = todo_to_json(item) |> json.to_string()
          server.json_response(201, body)
        }
        CreateErrorResult(ValidationErrorCreate(errors)) -> {
          let field_errors = parse_validation_errors(errors)
          validation_error_response(field_errors)
        }
      }
    }
    Error(msg) -> bad_request_response(msg)
  }
}

fn get_todo_handler(store: Store, id: String) -> Response {
  case todo_store.get_api(store, id) {
    GetOkResult(item) -> {
      let body = todo_to_json(item) |> json.to_string()
      server.json_response(200, body)
    }
    GetErrorResult(_) -> todo_not_found()
  }
}

fn update_todo_handler(store: Store, id: String, request: Request) -> Response {
  // Parse JSON payload
  let result = parse_json_payload(request.body)
  case result {
    Ok(changes) -> {
      case todo_store.update_api(store, id, changes) {
        UpdateOkResult(item) -> {
          let body = todo_to_json(item) |> json.to_string()
          server.json_response(200, body)
        }
        UpdateErrorResult(NotFoundUpdate) -> todo_not_found()
        UpdateErrorResult(ValidationErrorUpdate(errors)) -> {
          let field_errors = parse_validation_errors(errors)
          validation_error_response(field_errors)
        }
      }
    }
    Error(msg) -> bad_request_response(msg)
  }
}

fn delete_todo_handler(store: Store, id: String) -> Response {
  case todo_store.delete_api(store, id) {
    DeleteOkResult -> no_content_response()
    DeleteErrorResult(NotFoundDelete) -> todo_not_found()
  }
}

// ============================================
// JSON Parsing and Serialization
// ============================================

import gleam/dynamic/decode
import gleam/list

fn parse_json_payload(body: String) -> Result(List(#(String, String)), String) {
  // Parse JSON and extract fields as key-value pairs
  let decoder = decode.dict(decode.string, decode.string)

  case json.parse(from: body, using: decoder) {
    Ok(dict) -> {
      let pairs = dict.to_list(dict)
      Ok(pairs)
    }
    Error(_) -> {
      // Try to parse as a simple object with fields
      let decoder = {
        use title <- decode.optional_field("title", None, decode.optional(decode.string))
        use description <- decode.optional_field("description", None, decode.optional(decode.string))
        use priority <- decode.optional_field("priority", None, decode.optional(decode.string))
        use completed <- decode.optional_field("completed", None, decode.optional(decode.string))
        decode.success(#(title, description, priority, completed))
      }

      case json.parse(from: body, using: decoder) {
        Ok(#(title, description, priority, completed)) -> {
          let payload = []
          let payload = case title {
            Some(t) -> [#("title", t), ..payload]
            None -> payload
          }
          let payload = case description {
            Some(d) -> [#("description", d), ..payload]
            None -> payload
          }
          let payload = case priority {
            Some(p) -> [#("priority", p), ..payload]
            None -> payload
          }
          let payload = case completed {
            Some(c) -> [#("completed", c), ..payload]
            None -> payload
          }
          Ok(list.reverse(payload))
        }
        Error(_) -> Error("Invalid JSON")
      }
    }
  }
}

fn todo_to_json(item: todo_store.Todo) -> json.Json {
  let description_json = case item.description {
    Some(d) -> json.string(d)
    None -> json.null()
  }

  json.object([
    #("id", json.string(item.id)),
    #("title", json.string(item.title)),
    #("description", description_json),
    #("priority", json.string(item.priority)),
    #("completed", json.bool(item.completed)),
    #("created_at", json.int(item.created_at)),
  ])
}

// Validation error type
type FieldError {
  FieldError(field: String, message: String)
}

/// Parse validation error strings into structured FieldErrors
fn parse_validation_errors(error_strings: List(String)) -> List(FieldError) {
  list.map(error_strings, fn(err) {
    // Parse error messages like "title is required"
    let parts = string.split(err, " ")
    let field = case parts {
      [first, ..] -> first
      [] -> "unknown"
    }
    FieldError(field: field, message: err)
  })
}
