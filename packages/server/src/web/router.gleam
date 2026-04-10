import gleam/dict
import gleam/int
import gleam/json
import gleam/string
import web_auth
import db/drink_ratings
import shared
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
    "GET", "/api/users/me/ratings/drinks" -> user_drink_ratings_handler(request)
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

fn not_found() -> Response {
  server.json_response(
    404,
    json.object([#("error", json.string("Not found"))])
    |> json.to_string,
  )
}

// GET /api/users/me/ratings/drinks?page={number}&limit={number}
fn user_drink_ratings_handler(request: Request) -> Response {
  // Authenticate user
  case web_auth.authenticate_user(request.headers) {
    Error(shared.Unauthorized(msg)) -> {
      server.json_response(
        401,
        json.object([#("error", json.string(msg))])
        |> json.to_string,
      )
    }
    Error(_) -> {
      server.json_response(
        401,
        json.object([#("error", json.string("Unauthorized"))])
        |> json.to_string,
      )
    }
    Ok(user) -> {
      // Parse pagination parameters
      let page = parse_query_int(request.headers, "page", 1)
      let limit = parse_query_int(request.headers, "limit", 10)

      // Clamp values to reasonable ranges
      let clamped_page = int.max(1, page)
      let clamped_limit = int.clamp(limit, 1, 100)

      // Fetch ratings from database
      let response = drink_ratings.get_user_drink_ratings(
        user.id,
        clamped_page,
        clamped_limit,
      )

      // Return JSON response
      server.json_response(
        200,
        shared.paginated_response_to_json(response, shared.drink_rating_to_json)
        |> json.to_string,
      )
    }
  }
}

// Parse query parameter from request (simplified - assumes query in body or uses defaults)
// In production, this would parse request.path or request.body for query params
fn parse_query_int(headers: dict.Dict(String, String), key: String, default: Int) -> Int {
  // Stub: Parse from a custom header for now
  // In production, this parses actual query strings
  case dict.get(headers, "x-query-" <> key) {
    Ok(value) -> {
      case int.parse(value) {
        Ok(n) -> n
        Error(_) -> default
      }
    }
    Error(_) -> default
  }
}
