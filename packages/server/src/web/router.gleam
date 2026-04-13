import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/string
import shared.{type Priority, Low, Medium, High, todo_to_json}
import todo_store
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
    "PATCH", path -> route_patch(path, request)
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

fn route_patch(path: String, request: Request) -> Response {
  case string.starts_with(path, "/api/todos/") {
    True -> patch_todo_handler(path, request)
    False -> not_found()
  }
}

fn patch_todo_handler(path: String, request: Request) -> Response {
  let id = string.drop_start(path, string.length("/api/todos/"))

  // Parse and validate the patch body
  let patch_result = parse_patch_body(request.body)

  case patch_result {
    Error(errors) ->
      server.json_response(
        422,
        json.object([
          #("errors", json.array(errors, fn(e) {
            json.object([#("field", json.string(e.0)), #("message", json.string(e.1))])
          })),
        ])
        |> json.to_string,
      )

    Ok(#(title_opt, description_opt, priority_opt, completed_opt)) -> {
      case todo_store.patch(id, title_opt, description_opt, priority_opt, completed_opt) {
        Ok(todo_item) -> server.json_response(200, todo_to_json(todo_item))
        Error(_) ->
          server.json_response(
            404,
            json.object([#("error", json.string("Todo not found"))])
            |> json.to_string,
          )
      }
    }
  }
}

fn parse_patch_body(body: String) -> Result(#(Option(String), Option(Option(String)), Option(Priority), Option(Bool)), List(#(String, String))) {
  // For empty body, return all None values (no changes)
  let trimmed = string.trim(body)
  case trimmed {
    "{}" | "" -> Ok(#(None, None, None, None))
    _ -> {
      let errors = []

      // Extract title if present
      let title_opt = extract_optional_string_field(body, "title")
      let errors = case title_opt {
        Some("") -> [#("title", "Title cannot be empty"), ..errors]
        _ -> errors
      }

      // Extract description if present
      let description_opt = extract_nullable_string_field(body, "description")

      // Extract priority if present
      let priority_result = case extract_raw_field(body, "priority") {
        None -> #(None, errors)
        Some("null") -> #(None, errors)
        Some(raw) -> {
          case raw {
            "\"low\"" -> #(Some(Low), errors)
            "\"medium\"" -> #(Some(Medium), errors)
            "\"high\"" -> #(Some(High), errors)
            _ -> #(None, [#("priority", "Invalid priority value"), ..errors])
          }
        }
      }
      let priority_opt = priority_result.0
      let errors = priority_result.1

      // Extract completed if present
      let completed_opt = case extract_raw_field(body, "completed") {
        None -> None
        Some("true") -> Some(True)
        Some("false") -> Some(False)
        _ -> None
      }

      case errors {
        [] -> Ok(#(title_opt, description_opt, priority_opt, completed_opt))
        _ -> Error(errors)
      }
    }
  }
}

fn extract_optional_string_field(json: String, field: String) -> Option(String) {
  case extract_raw_field(json, field) {
    None -> None
    Some(raw) -> {
      case raw {
        "\"" <> rest -> {
          case string.split(rest, "\"") {
            [value, ..] -> Some(value)
            _ -> None
          }
        }
        _ -> None
      }
    }
  }
}

fn extract_nullable_string_field(json: String, field: String) -> Option(Option(String)) {
  case extract_raw_field(json, field) {
    None -> None
    Some("null") -> Some(None)
    Some(raw) -> {
      case raw {
        "\"" <> rest -> {
          case string.split(rest, "\"") {
            [value, ..] -> Some(Some(value))
            _ -> None
          }
        }
        _ -> None
      }
    }
  }
}

fn extract_raw_field(json: String, field: String) -> Option(String) {
  let pattern = "\"" <> field <> "\":"
  case string.split(json, pattern) {
    [_, rest] -> {
      let rest = string.trim_start(rest)
      // Find the value - could be string, bool, null, or number
      case rest {
        "null" <> _ -> Some("null")
        "true" <> _ -> Some("true")
        "false" <> _ -> Some("false")
        "\"" <> quoted -> {
          case string.split(quoted, "\"") {
            [value, ..] -> Some("\"" <> value <> "\"")
            _ -> None
          }
        }
        _ -> {
          // Try to extract number or other value until next comma or brace
          case string.split(rest, ",") {
            [before_comma, ..] -> {
              case string.split(before_comma, "}") {
                [before_brace, ..] -> Some(string.trim(before_brace))
                _ -> Some(string.trim(before_comma))
              }
            }
            _ -> {
              case string.split(rest, "}") {
                [before_brace, ..] -> Some(string.trim(before_brace))
                _ -> Some(string.trim(rest))
              }
            }
          }
        }
      }
    }
    _ -> None
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
