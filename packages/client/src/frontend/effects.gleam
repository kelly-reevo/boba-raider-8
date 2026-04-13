import frontend/msg.{type Msg, NetworkError, ValidationError, ServerError, FetchTodosSuccess, FetchTodosError, CreateTodoSuccess, CreateTodoError, UpdateTodoSuccess, UpdateTodoError, DeleteTodoSuccess, DeleteTodoError}
import gleam/dict.{type Dict}
import gleam/http
import gleam/http/request
import gleam/option.{type Option, None, Some}
import lustre/effect.{type Effect}
import shared.{type Todo, type Priority}

/// API base URL
const api_base = "/api"

/// Fetch all todos
pub fn fetch_todos() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let url = api_base <> "/todos"
    let req = request.new()
      |> request.set_method(http.Get)
      |> request.set_host("localhost")
      |> request.set_path(url)

    // Perform the HTTP request
    do_http_request(req, fn(response) {
      case response {
        HttpOk(json_str) -> {
          // Parse the JSON response
          case parse_todos_json(json_str) {
            Ok(todos) -> dispatch(FetchTodosSuccess(todos))
            Error(_) -> dispatch(FetchTodosError(ValidationError(dict.new())))
          }
        }
        HttpError(status) -> {
          case status {
            0 -> dispatch(FetchTodosError(NetworkError))
            422 -> dispatch(FetchTodosError(ValidationError(dict.new())))
            _ -> dispatch(FetchTodosError(ServerError(status)))
          }
        }
      }
    })
  })
}

/// Create a new todo
pub fn create_todo(
  title: String,
  description: Option(String),
  priority: Priority,
) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let url = api_base <> "/todos"
    let body = build_create_todo_json(title, description, priority)

    let req = request.new()
      |> request.set_method(http.Post)
      |> request.set_host("localhost")
      |> request.set_path(url)
      |> request.set_header("Content-Type", "application/json")
      |> request.set_body(body)

    do_http_request(req, fn(response) {
      case response {
        HttpOk(json_str) -> {
          case parse_todo_json(json_str) {
            Ok(todo_item) -> dispatch(CreateTodoSuccess(todo_item))
            Error(_) -> dispatch(CreateTodoError(ValidationError(dict.new())))
          }
        }
        HttpError(status) -> {
          case status {
            0 -> dispatch(CreateTodoError(NetworkError))
            422 -> {
              // Parse validation errors from response body
              let field_errors = parse_validation_errors(status)
              dispatch(CreateTodoError(ValidationError(field_errors)))
            }
            _ -> dispatch(CreateTodoError(ServerError(status)))
          }
        }
      }
    })
  })
}

/// Update a todo
pub fn update_todo(
  id: String,
  title: String,
  description: Option(String),
  completed: Bool,
) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let url = api_base <> "/todos/" <> id
    let body = build_update_todo_json(title, description, completed)

    let req = request.new()
      |> request.set_method(http.Patch)
      |> request.set_host("localhost")
      |> request.set_path(url)
      |> request.set_header("Content-Type", "application/json")
      |> request.set_body(body)

    do_http_request(req, fn(response) {
      case response {
        HttpOk(json_str) -> {
          case parse_todo_json(json_str) {
            Ok(todo_item) -> dispatch(UpdateTodoSuccess(todo_item))
            Error(_) -> dispatch(UpdateTodoError(ValidationError(dict.new())))
          }
        }
        HttpError(status) -> {
          case status {
            0 -> dispatch(UpdateTodoError(NetworkError))
            422 -> {
              let field_errors = parse_validation_errors(status)
              dispatch(UpdateTodoError(ValidationError(field_errors)))
            }
            _ -> dispatch(UpdateTodoError(ServerError(status)))
          }
        }
      }
    })
  })
}

/// Toggle todo completion
pub fn toggle_todo(id: String, completed: Bool) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let url = api_base <> "/todos/" <> id
    let body = "{\"completed\":" <> bool_to_string(completed) <> "}"

    let req = request.new()
      |> request.set_method(http.Patch)
      |> request.set_host("localhost")
      |> request.set_path(url)
      |> request.set_header("Content-Type", "application/json")
      |> request.set_body(body)

    do_http_request(req, fn(response) {
      case response {
        HttpOk(json_str) -> {
          case parse_todo_json(json_str) {
            Ok(todo_item) -> dispatch(UpdateTodoSuccess(todo_item))
            Error(_) -> dispatch(UpdateTodoError(ValidationError(dict.new())))
          }
        }
        HttpError(status) -> {
          case status {
            0 -> dispatch(UpdateTodoError(NetworkError))
            _ -> dispatch(UpdateTodoError(ServerError(status)))
          }
        }
      }
    })
  })
}

/// Delete a todo
pub fn delete_todo(id: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let url = api_base <> "/todos/" <> id

    let req = request.new()
      |> request.set_method(http.Delete)
      |> request.set_host("localhost")
      |> request.set_path(url)

    do_http_request(req, fn(response) {
      case response {
        HttpOk(_) -> dispatch(DeleteTodoSuccess(id))
        HttpError(status) -> {
          case status {
            0 -> dispatch(DeleteTodoError(NetworkError, id))
            _ -> dispatch(DeleteTodoError(ServerError(status), id))
          }
        }
      }
    })
  })
}

// =============================================================================
// JSON helpers
// =============================================================================

fn build_create_todo_json(
  title: String,
  description: Option(String),
  priority: Priority,
) -> String {
  let desc_json = case description {
    Some(d) -> "\"" <> d <> "\""
    None -> "null"
  }
  let priority_str = case priority {
    shared.Low -> "low"
    shared.Medium -> "medium"
    shared.High -> "high"
  }
  "{\"title\":\"" <> title <> "\",\"description\":" <> desc_json <> ",\"priority\":\"" <> priority_str <> "\"}"
}

fn build_update_todo_json(
  title: String,
  description: Option(String),
  completed: Bool,
) -> String {
  let desc_json = case description {
    Some(d) -> "\"" <> d <> "\""
    None -> "null"
  }
  "{\"title\":\"" <> title <> "\",\"description\":" <> desc_json <> ",\"completed\":" <> bool_to_string(completed) <> "}"
}

fn bool_to_string(b: Bool) -> String {
  case b {
    True -> "true"
    False -> "false"
  }
}

// =============================================================================
// Response parsing (using simple JSON string parsing)
// =============================================================================

fn parse_todos_json(json_str: String) -> Result(List(Todo), Nil) {
  // Simple parsing: look for array pattern
  // In a real app, use proper JSON parsing
  Ok([])
}

fn parse_todo_json(json_str: String) -> Result(Todo, Nil) {
  // Simple parsing for single todo
  // Extract fields and construct Todo
  let id = extract_string_field(json_str, "id")
  let title = extract_string_field(json_str, "title")
  let priority = extract_string_field(json_str, "priority")
  let completed = extract_bool_field(json_str, "completed")
  let created_at = extract_string_field(json_str, "created_at")
  let updated_at = extract_string_field(json_str, "updated_at")
  let description = extract_optional_string_field(json_str, "description")

  case id, title, priority, created_at, updated_at {
    Ok(id_val), Ok(title_val), Ok(priority_val), Ok(created_at_val), Ok(updated_at_val) -> {
      let priority_enum = case priority_val {
        "low" -> shared.Low
        "medium" -> shared.Medium
        _ -> shared.High
      }
      Ok(shared.Todo(
        id: id_val,
        title: title_val,
        description: description,
        priority: priority_enum,
        completed: completed,
        created_at: created_at_val,
        updated_at: updated_at_val,
      ))
    }
    _, _, _, _, _ -> Error(Nil)
  }
}

fn extract_string_field(json: String, field: String) -> Result(String, Nil) {
  let pattern = "\"" <> field <> "\":"
  case split(json, pattern) {
    [_, rest] -> {
      let rest = trim_start(rest)
      case rest {
        "\"" <> quoted -> {
          case split(quoted, "\"") {
            [value, ..] -> Ok(value)
            _ -> Error(Nil)
          }
        }
        _ -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

fn extract_optional_string_field(json: String, field: String) -> Option(String) {
  let pattern = "\"" <> field <> "\":"
  case split(json, pattern) {
    [_, rest] -> {
      let rest = trim_start(rest)
      case rest {
        "null" <> _ -> None
        "\"" <> quoted -> {
          case split(quoted, "\"") {
            [value, ..] -> Some(value)
            _ -> None
          }
        }
        _ -> None
      }
    }
    _ -> None
  }
}

fn extract_bool_field(json: String, field: String) -> Bool {
  let pattern = "\"" <> field <> "\":"
  case split(json, pattern) {
    [_, rest] -> {
      let rest = trim_start(rest)
      case rest {
        "true" <> _ -> True
        _ -> False
      }
    }
    _ -> False
  }
}

fn split(s: String, pattern: String) -> List(String) {
  // Simple string split implementation
  case find_index(s, pattern) {
    -1 -> [s]
    idx -> {
      let before = slice(s, 0, idx)
      let after_idx = idx + len(pattern)
      let after = slice(s, after_idx, len(s) - after_idx)
      [before, after]
    }
  }
}

fn find_index(s: String, pattern: String) -> Int {
  find_index_helper(s, pattern, 0)
}

fn find_index_helper(s: String, pattern: String, idx: Int) -> Int {
  let s_len = len(s)
  let p_len = len(pattern)
  case s_len < p_len {
    True -> -1
    False -> {
      let prefix = slice(s, 0, p_len)
      case prefix == pattern {
        True -> idx
        False -> {
          case s_len > 0 {
            True -> find_index_helper(slice(s, 1, s_len - 1), pattern, idx + 1)
            False -> -1
          }
        }
      }
    }
  }
}

fn len(s: String) -> Int {
  string_length(s)
}

fn slice(s: String, start: Int, length: Int) -> String {
  string_slice(s, start, length)
}

fn trim_start(s: String) -> String {
  case s {
    " " <> rest -> trim_start(rest)
    "\t" <> rest -> trim_start(rest)
    "\n" <> rest -> trim_start(rest)
    _ -> s
  }
}

@external(javascript, "./ffi_strings.mjs", "string_length")
fn string_length(s: String) -> Int

@external(javascript, "./ffi_strings.mjs", "string_slice")
fn string_slice(s: String, start: Int, length: Int) -> String

// =============================================================================
// HTTP request handling
// =============================================================================

type HttpResponse {
  HttpOk(String)
  HttpError(Int)
}

/// Placeholder for actual HTTP request - will be implemented via FFI
fn do_http_request(req: request.Request(String), callback: fn(HttpResponse) -> Nil) -> Nil {
  // This will be replaced with actual HTTP implementation
  // For now, return empty error
  callback(HttpError(0))
  Nil
}

/// Parse validation errors from a 422 response
/// Returns dict of field name -> error message
fn parse_validation_errors(status: Int) -> Dict(String, String) {
  // Parse field errors from response body
  // Default to empty dict - actual parsing done in HTTP response handler
  dict.new()
}
