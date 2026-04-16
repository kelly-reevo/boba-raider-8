import counter.{type CounterMsg}
import gleam/dict
import gleam/dynamic/decode
import gleam/erlang/process.{type Subject}
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import shared.{type Priority, NotFound, todo_to_json}
import shared/todo_validation.{TodoPatch}
import todo_actor.{type TodoMsg}
import web/server.{type Request, type Response, Response}
import web/static

pub fn make_handler(
  counter: Subject(CounterMsg),
  todo_subject: Subject(TodoMsg),
) -> fn(Request) -> Response {
  fn(request: Request) { route(request, counter, todo_subject) }
}

fn get_path_without_query(path: String) -> String {
  case string.split(path, "?") {
    [base_path, ..] -> base_path
    _ -> path
  }
}

fn route(
  request: Request,
  counter: Subject(CounterMsg),
  todo_subject: Subject(TodoMsg),
) -> Response {
  // Strip query string for exact path matching
  let base_path = get_path_without_query(request.path)

  case request.method, base_path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "GET", "/api/counter" -> get_counter(counter)
    "POST", "/api/counter/increment" -> increment_counter(counter)
    "POST", "/api/counter/decrement" -> decrement_counter(counter)
    "POST", "/api/counter/reset" -> reset_counter(counter)
    // Todo endpoints - specific paths first
    "GET", "/api/todos" -> list_todos_handler(request, todo_subject)
    "POST", "/api/todos" -> create_todo_handler(request, todo_subject)
    "OPTIONS", "/api/todos" -> Response(status: 204, headers: cors_headers(), body: "")
    // Todo endpoints with ID - match by pattern (use base_path for matching)
    "GET", path -> route_get_todo(path, todo_subject)
    "PATCH", path -> route_patch_todo(request, path, todo_subject)
    "DELETE", path -> route_delete_todo(path, todo_subject)
    "OPTIONS", path -> route_options(path)
    _, _ -> not_found()
  }
}

// GET /api/todos/:id
fn route_get_todo(path: String, todo_subject: Subject(TodoMsg)) -> Response {
  case extract_todo_id(path) {
    Ok(id) -> get_todo_handler(id, todo_subject)
    Error(_) -> route_get_static(path)
  }
}

// PATCH /api/todos/:id
fn route_patch_todo(
  request: Request,
  path: String,
  todo_subject: Subject(TodoMsg),
) -> Response {
  case extract_todo_id(path) {
    Ok(id) -> patch_todo_handler(request, id, todo_subject)
    Error(_) -> not_found()
  }
}

// DELETE /api/todos/:id
fn route_delete_todo(
  path: String,
  todo_subject: Subject(TodoMsg),
) -> Response {
  case extract_todo_id(path) {
    Ok(id) -> delete_todo_handler(todo_subject, id)
    Error(_) -> not_found()
  }
}

fn extract_todo_id(path: String) -> Result(String, Nil) {
  case string.split(path, "/") {
    ["", "api", "todos", id] -> Ok(id)
    _ -> Error(Nil)
  }
}

// UUID validation: 8-4-4-4-12 hex format (lowercase only)
fn is_valid_uuid(id: String) -> Bool {
  case string.is_empty(id) {
    True -> False
    False -> {
      let segments = string.split(id, "-")
      case segments {
        [s1, s2, s3, s4, s5] -> {
          case
            string.length(s1),
            string.length(s2),
            string.length(s3),
            string.length(s4),
            string.length(s5)
          {
            8, 4, 4, 4, 12 -> {
              let all_chars = s1 <> s2 <> s3 <> s4 <> s5
              is_valid_hex_string(all_chars)
            }
            _, _, _, _, _ -> False
          }
        }
        _ -> False
      }
    }
  }
}

fn is_valid_hex_string(s: String) -> Bool {
  let chars = string.to_graphemes(s)
  list.all(chars, is_valid_hex_char)
}

fn is_valid_hex_char(c: String) -> Bool {
  case c {
    "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> True
    "a" | "b" | "c" | "d" | "e" | "f" -> True
    _ -> False
  }
}

// GET /api/todos/:id handler
fn get_todo_handler(id: String, todo_subject: Subject(TodoMsg)) -> Response {
  // For REST API consistency, both invalid format and not-found return 404
  // This prevents information leakage about valid ID formats
  case is_valid_uuid(id) {
    False ->
      json_response(
        404,
        json.object([#("error", json.string("not_found"))])
          |> json.to_string,
      )
    True -> {
      case todo_actor.get_todo(todo_subject, id) {
        Ok(found_todo) ->
          json_response(
            200,
            todo_to_json(found_todo) |> json.to_string,
          )
        Error(NotFound) ->
          json_response(
            404,
            json.object([#("error", json.string("not_found"))])
              |> json.to_string,
          )
        Error(_) ->
          json_response(
            500,
            json.object([#("error", json.string("internal_error"))])
              |> json.to_string,
          )
      }
    }
  }
}

// PATCH /api/todos/:id handler
fn patch_todo_handler(
  request: Request,
  todo_id: String,
  todo_subject: Subject(TodoMsg),
) -> Response {
  // Build decoder for optional patch fields
  let patch_decoder = {
    use title_opt <- decode.field("title", decode.optional(decode.string))
    use description_opt <- decode.field(
      "description",
      decode.optional(decode.string),
    )
    use priority_opt <- decode.field("priority", decode.optional(decode.string))
    use completed_opt <- decode.field("completed", decode.optional(decode.bool))
    decode.success(#(title_opt, description_opt, priority_opt, completed_opt))
  }

  case json.parse(request.body, patch_decoder) {
    Ok(#(title_opt, description_opt, priority_opt, completed_opt)) -> {
      // Convert string priority to Priority type if present
      let parsed_priority = case priority_opt {
        Some(p) -> parse_priority_string(p)
        None -> Ok(None)
      }

      case parsed_priority {
        Ok(priority_value) -> {
          let patch =
            TodoPatch(
              title: title_opt,
              description: description_opt,
              priority: priority_value,
              completed: completed_opt,
            )

          case todo_actor.update_todo(todo_subject, todo_id, patch) {
            Ok(updated_todo) ->
              json_response(
                200,
                todo_to_json(updated_todo) |> json.to_string,
              )
            Error(NotFound) ->
              json_response(
                404,
                json.object([#("error", json.string("not_found"))])
                  |> json.to_string,
              )
            Error(_) ->
              json_response(
                500,
                json.object([#("error", json.string("internal_error"))])
                  |> json.to_string,
              )
          }
        }
        Error(_) ->
          json_response(
            400,
            json.object([#("errors", json.array(["Invalid priority value"], json.string))])
              |> json.to_string,
          )
      }
    }
    Error(_) ->
      json_response(
        400,
        json.object([#("errors", json.array(["Invalid JSON in request body"], json.string))])
          |> json.to_string,
      )
  }
}

fn parse_priority_string(p: String) -> Result(Option(Priority), Nil) {
  case p {
    "low" -> Ok(Some(shared.Low))
    "medium" -> Ok(Some(shared.Medium))
    "high" -> Ok(Some(shared.High))
    _ -> Error(Nil)
  }
}

// DELETE /api/todos/:id handler
fn delete_todo_handler(
  todo_subject: Subject(TodoMsg),
  id: String,
) -> Response {
  // Validate UUID format first
  case is_valid_uuid(id) {
    False ->
      json_response(
        404,
        json.object([#("error", json.string("not_found"))]) |> json.to_string,
      )
    True -> {
      case todo_actor.delete_todo(todo_subject, id) {
        Ok(True) -> Response(status: 204, headers: cors_headers(), body: "")
        Ok(False) | Error(NotFound) ->
          json_response(
            404,
            json.object([#("error", json.string("not_found"))]) |> json.to_string,
          )
        Error(_) ->
          json_response(
            500,
            json.object([#("error", json.string("internal_error"))])
              |> json.to_string,
          )
      }
    }
  }
}

// GET /api/todos handler
fn list_todos_handler(
  request: Request,
  todo_subject: Subject(TodoMsg),
) -> Response {
  let filter = parse_filter(request.path)
  case filter {
    Ok(filter_opt) -> {
      let all_todos = todo_actor.get_all_todos(todo_subject)
      let filtered_todos = case filter_opt {
        Some("active") -> list.filter(all_todos, fn(t) { !t.completed })
        Some("completed") -> list.filter(all_todos, fn(t) { t.completed })
        _ -> all_todos
      }
      let body =
        json.array(filtered_todos, todo_to_json) |> json.to_string
      json_response(200, body)
    }
    Error(_) -> {
      let body =
        json.object([#("error", json.string("Invalid filter value"))])
        |> json.to_string
      json_response(400, body)
    }
  }
}

fn parse_filter(path: String) -> Result(Option(String), Nil) {
  // Extract query string from path (everything after ?)
  case string.split(path, "?") {
    [_, query_string] -> {
      // Parse query parameters
      let params = parse_query_string(query_string)
      case dict.get(params, "filter") {
        Ok("active") -> Ok(Some("active"))
        Ok("completed") -> Ok(Some("completed"))
        Ok("all") -> Ok(None)
        Ok(_) -> Error(Nil)
        Error(_) -> Ok(None)
      }
    }
    _ -> Ok(None)
  }
}

fn parse_query_string(query_string: String) -> dict.Dict(String, String) {
  case string.is_empty(query_string) {
    True -> dict.new()
    False -> {
      let pairs = string.split(query_string, "&")
      list.fold(pairs, dict.new(), fn(acc, pair) {
        case string.split(pair, "=") {
          [key, value] -> dict.insert(acc, key, value)
          _ -> acc
        }
      })
    }
  }
}

// POST /api/todos handler
fn create_todo_handler(
  request: Request,
  todo_subject: Subject(TodoMsg),
) -> Response {
  // Decoder for create todo request
  let create_decoder = {
    use title <- decode.field("title", decode.optional(decode.string))
    use description <- decode.field(
      "description",
      decode.optional(decode.string),
    )
    use priority <- decode.field("priority", decode.optional(decode.string))
    decode.success(#(title, description, priority))
  }

  case json.parse(request.body, create_decoder) {
    Ok(#(title_opt, description_opt, priority_opt)) -> {
      let title = option.unwrap(title_opt, "")
      // Priority is required - use unwrap with empty string then validate
      let priority = option.unwrap(priority_opt, "")

      // Validate that priority is not empty
      case priority {
        "" -> {
          let body =
            json.object([#("errors", json.array(["Priority is required"], json.string))])
            |> json.to_string
          json_response(400, body)
        }
        _ -> {
          case
            todo_validation.validate_todo_input(title, description_opt, priority)
          {
            Ok(validated_input) -> {
              let created_todo =
                todo_actor.create_todo(
                  todo_subject,
                  validated_input.title,
                  validated_input.description,
                  validated_input.priority,
                )
              json_response(201, todo_to_json(created_todo) |> json.to_string)
            }
            Error(validation_errors) -> {
              let body =
                json.object([#("errors", json.array(validation_errors, json.string))])
                |> json.to_string
              json_response(400, body)
            }
          }
        }
      }
    }
    Error(_) -> {
      let body =
        json.object([#("errors", json.array(["Invalid JSON"], json.string))])
        |> json.to_string
      json_response(400, body)
    }
  }
}

fn route_get_static(path: String) -> Response {
  case string.starts_with(path, "/static/") {
    True -> static.serve(path)
    False -> not_found()
  }
}

fn health_handler() -> Response {
  json_response(
    200,
    json.object([#("status", json.string("ok"))]) |> json.to_string,
  )
}

fn not_found() -> Response {
  json_response(
    404,
    json.object([#("error", json.string("Not found"))]) |> json.to_string,
  )
}

fn get_counter(counter: Subject(CounterMsg)) -> Response {
  counter.get_count(counter) |> counter_response
}

fn increment_counter(counter: Subject(CounterMsg)) -> Response {
  counter.increment(counter) |> counter_response
}

fn decrement_counter(counter: Subject(CounterMsg)) -> Response {
  counter.decrement(counter) |> counter_response
}

fn reset_counter(counter: Subject(CounterMsg)) -> Response {
  counter.reset(counter) |> counter_response
}

fn counter_response(count: Int) -> Response {
  let body =
    json.object([#("count", json.int(count))]) |> json.to_string
  json_response(200, body)
}

fn json_response(status: Int, body: String) -> Response {
  Response(
    status: status,
    headers: cors_headers()
      |> dict.insert("Content-Type", "application/json"),
    body: body,
  )
}

fn route_options(path: String) -> Response {
  case string.starts_with(path, "/api/") {
    True -> Response(status: 204, headers: cors_headers(), body: "")
    False -> not_found()
  }
}

fn cors_headers() -> dict.Dict(String, String) {
  dict.from_list([
    #("Access-Control-Allow-Origin", "*"),
    #("Access-Control-Allow-Methods", "GET, POST, PATCH, DELETE, OPTIONS"),
    #("Access-Control-Allow-Headers", "Content-Type"),
  ])
}
