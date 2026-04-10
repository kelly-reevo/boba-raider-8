import gleam/json
import gleam/string
import users.{RegisterSuccess, RegisterValidationError, RegisterConflict}
import web/auth/login
import web/server.{type Request, type Response}
import web/static
import web/user_store.{type UserStore}

pub fn make_handler(
  store: UserStore,
  jwt_secret: String,
) -> fn(Request) -> Response {
  fn(request: Request) { route(request, store, jwt_secret) }
}

fn route(request: Request, store: UserStore, jwt_secret: String) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "POST", "/api/auth/register" -> register_handler(request, store)
    "POST", "/api/auth/login" -> login.handle_login(request, store, jwt_secret)
    "POST", "/api/auth/refresh" -> refresh_handler(request)
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

fn health_handler() -> Response {
  server.json_response(
    200,
    json.object([#("status", json.string("ok"))])
    |> json.to_string,
  )
}

fn register_handler(request: Request, store: UserStore) -> Response {
  case users.parse_register_request(request.body) {
    Ok(req) -> {
      case users.register(store, req) {
        RegisterSuccess(user) -> {
          server.json_response(
            201,
            users.user_to_json(user)
            |> json.to_string,
          )
        }
        RegisterValidationError(errors) -> {
          server.json_response(
            422,
            users.errors_to_json(errors)
            |> json.to_string,
          )
        }
        RegisterConflict(msg) -> {
          server.json_response(
            409,
            json.object([#("error", json.string(msg))])
            |> json.to_string,
          )
        }
      }
    }
    Error(msg) -> {
      server.json_response(
        422,
        json.object([
          #("errors", json.array(
            [json.object([#("field", json.string("")), #("message", json.string(msg))])],
            fn(x) { x },
          )),
        ])
        |> json.to_string,
      )
    }
  }
}

fn refresh_handler(request: Request) -> Response {
  // Parse request body to extract refresh_token
  case parse_refresh_request(request.body) {
    Ok("") -> {
      // Empty token provided
      server.json_response(
        401,
        json.object([#("error", json.string("Invalid or missing refresh token"))])
        |> json.to_string(),
      )
    }
    Ok(refresh_token) -> {
      // Valid token provided - return new pair
      // In full implementation with unit-2, this would validate against token store
      server.json_response(
        200,
        json.object([
          #("access_token", json.string("new_access_token_" <> refresh_token)),
          #("refresh_token", json.string("new_refresh_token_" <> refresh_token)),
        ])
        |> json.to_string(),
      )
    }
    Error(Nil) -> {
      // Invalid/malformed request
      server.json_response(
        401,
        json.object([#("error", json.string("Invalid request body"))])
        |> json.to_string(),
      )
    }
  }
}

fn parse_refresh_request(body: String) -> Result(String, Nil) {
  // Simple manual JSON parsing for { "refresh_token": "value" }
  // Remove whitespace and check structure
  let trimmed = string.trim(body)

  // Check if it starts with { and ends with }
  case string.starts_with(trimmed, "{"), string.ends_with(trimmed, "}") {
    True, True -> {
      // Extract content between braces
      let len = string.length(trimmed)
      let content = trimmed
        |> string.slice(1, len - 2)
        |> string.trim()

      // Look for refresh_token field
      case extract_json_string_field(content, "refresh_token") {
        Ok(token) if token != "" -> Ok(token)
        _ -> Error(Nil)
      }
    }
    _, _ -> Error(Nil)
  }
}

/// Extract a string value from a simple JSON object content (without outer braces)
/// Handles: "field_name": "value" or "field_name":"value"
fn extract_json_string_field(content: String, field_name: String) -> Result(String, Nil) {
  // Look for field name in quotes followed by colon
  let pattern = "\"" <> field_name <> "\""

  case string.split(content, pattern) {
    [_, after_field] -> {
      // Skip whitespace and colon
      let after_field_trimmed = string.trim(after_field)

      case string.starts_with(after_field_trimmed, ":") {
        True -> {
          let after_colon = after_field_trimmed
            |> string.slice(1, string.length(after_field_trimmed) - 1)
            |> string.trim()

          // Expect opening quote for string value
          case string.starts_with(after_colon, "\"") {
            True -> {
              let after_open_quote = string.slice(after_colon, 1, string.length(after_colon) - 1)
              extract_quoted_string(after_open_quote)
            }
            False -> Error(Nil)
          }
        }
        False -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

/// Extract string content until closing quote (handles no escapes)
fn extract_quoted_string(s: String) -> Result(String, Nil) {
  extract_quoted_string_impl(s, "")
}

fn extract_quoted_string_impl(s: String, acc: String) -> Result(String, Nil) {
  case string.pop_grapheme(s) {
    Ok(#(c, rest)) -> {
      case c {
        "\"" -> Ok(acc)
        _ -> extract_quoted_string_impl(rest, acc <> c)
      }
    }
    Error(_) -> Error(Nil)
  }
}

fn not_found() -> Response {
  server.json_response(
    404,
    json.object([#("error", json.string("Not found"))])
    |> json.to_string,
  )
}
