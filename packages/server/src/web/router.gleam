import gleam/json
import gleam/string
import gleam/dynamic/decode
import web/server.{type Request, type Response}
import web/static
import todo_store.{type Store}
import shared

pub fn make_handler(store: Store) -> fn(Request) -> Response {
  fn(request: Request) { route(request, store) }
}

fn route(request: Request, store: Store) -> Response {
  case request.method, request.path {
    "POST", "/api/todos" -> create_todo_handler(request, store)
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
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

// POST /api/todos handler - creates a new todo
fn create_todo_handler(request: Request, store: Store) -> Response {
  // Parse the JSON body
  let parse_result = json.parse(request.body, create_todo_decoder())

  case parse_result {
    // Successfully parsed JSON
    Ok(parsed) -> {
      let trimmed_title = string.trim(parsed.title)

      // Validate title is not empty
      case string.is_empty(trimmed_title) {
        True -> {
          error_response(400, "Title is required")
        }
        False -> {
          // Validate title length (max 200 chars)
          case string.length(trimmed_title) > 200 {
            True -> {
              error_response(400, "Title is too long")
            }
            False -> {
              // Create the todo in the store
              case todo_store.create_todo(store, trimmed_title, parsed.description) {
                Ok(created_todo) -> {
                  // Return 201 with created todo JSON
                  server.json_response(
                    201,
                    shared.todo_to_json(created_todo) |> json.to_string,
                  )
                }
                Error(msg) -> {
                  error_response(400, msg)
                }
              }
            }
          }
        }
      }
    }

    // Failed to parse JSON
    Error(_) -> {
      error_response(400, "Title is required")
    }
  }
}

// Decoder for create todo request body
type CreateTodoRequest {
  CreateTodoRequest(title: String, description: String)
}

fn create_todo_decoder() -> decode.Decoder(CreateTodoRequest) {
  use title <- decode.field("title", decode.string)
  use description <- decode.optional_field(
    "description",
    "",
    decode.string,
  )
  decode.success(CreateTodoRequest(title:, description:))
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

fn error_response(status: Int, message: String) -> Response {
  server.json_response(
    status,
    json.object([#("error", json.string(message))])
    |> json.to_string,
  )
}
