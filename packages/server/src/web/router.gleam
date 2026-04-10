import data.{type Store, get_store_ratings}
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import handlers/rating_handler
import store/rating_store.{type RatingStore}
import web/server.{type Request, type Response}
import web/static

pub fn make_handler(store: RatingStore) -> fn(Request) -> Response {
  fn(request: Request) { route(request, store) }
}

fn route(request: Request, store: RatingStore) -> Response {
  case request.method, request.path {
    "GET", "/" -> static_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "DELETE", path -> route_delete(path, request, store)
    "GET", path -> route_get(path)
    _, _ -> not_found()
  }
}

fn route_get(path: String, store: Store) -> Response {
  case string.starts_with(path, "/static/") {
    True -> static_file(path)
    False -> {
      // Check for ratings endpoint pattern: /api/stores/:store_id/ratings
      case parse_ratings_path(path) {
        Ok(#(store_id, params)) -> {
          ratings_handler(store, store_id, params)
        }
        Error(Nil) -> not_found()
      }
    }
  }
}

fn parse_ratings_path(path: String) -> Result(#(String, QueryParams), Nil) {
  // Path format: /api/stores/:store_id/ratings?page=X&limit=Y
  let prefix = "/api/stores/"
  let suffix = "/ratings"

  case string.starts_with(path, prefix) {
    False -> Error(Nil)
    True -> {
      let rest = string.drop_start(path, string.length(prefix))
      case string.ends_with(rest, suffix) {
        False -> Error(Nil)
        True -> {
          let store_part = string.drop_end(rest, string.length(suffix))
          // Parse any query string
          let parts = string.split(store_part, "?")
          case parts {
            [store_id, _query] | [store_id] -> {
              let params = parse_query_params(case parts {
                [_, q] -> q
                _ -> ""
              })
              Ok(#(store_id, params))
            }
            _ -> Error(Nil)
          }
        }
      }
    }
  }
}

type QueryParams {
  QueryParams(page: Int, limit: Int)
}

fn parse_query_params(query: String) -> QueryParams {
  let pairs = string.split(query, "&")

  let page = get_int_param(pairs, "page", 1)
  let limit = get_int_param(pairs, "limit", 10)

  // Clamp limit to reasonable values
  let clamped_limit = case limit {
    n if n < 1 -> 1
    n if n > 100 -> 100
    _ -> limit
  }

  // Clamp page to minimum 1
  let clamped_page = case page {
    n if n < 1 -> 1
    _ -> page
  }

  QueryParams(page: clamped_page, limit: clamped_limit)
}

fn get_int_param(pairs: List(String), key: String, default: Int) -> Int {
  list.find(pairs, fn(p) { string.starts_with(p, key <> "=") })
  |> result.try(fn(p) {
    let parts = string.split(p, "=")
    case parts {
      [_, val] -> int.parse(val)
      _ -> Error(Nil)
    }
  })
  |> result.unwrap(default)
}

fn ratings_handler(store: Store, store_id: String, params: QueryParams) -> Response {
  case get_store_ratings(store, store_id, params.page, params.limit) {
    Ok(result) -> {
      let data = list.map(result.data, fn(rating) {
        json.object([
          #("id", json.string(rating.id)),
          #("user", json.object([
            #("id", json.string(rating.user.id)),
            #("username", json.string(rating.user.username))
          ])),
          #("overall_score", json.float(rating.overall_score)),
          #("review_text", case rating.review_text {
            option.Some(text) -> json.string(text)
            option.None -> json.null()
          }),
          #("created_at", json.string(rating.created_at)),
          #("updated_at", json.string(rating.updated_at))
        ])
      })

      let body = json.object([
        #("data", json.array(data, fn(x) { x })),
        #("meta", json.object([
          #("total", json.int(result.meta.total)),
          #("page", json.int(result.meta.page)),
          #("limit", json.int(result.meta.limit)),
          #("total_pages", json.int(result.meta.total_pages))
        ]))
      ])

      json_response(200, json.to_string(body))
    }
    Error(_) -> not_found()
  }
}

fn route_delete(path: String, request: Request, store: RatingStore) -> Response {
  // Match DELETE /api/ratings/store/:rating_id
  case parse_rating_delete_path(path) {
    Ok(rating_id) -> rating_handler.delete_store_rating(store, request, rating_id)
    Error(Nil) -> not_found()
  }
}

fn parse_rating_delete_path(path: String) -> Result(String, Nil) {
  // Parse /api/ratings/store/:rating_id pattern
  case string.split(path, "/") {
    ["", "api", "ratings", "store", rating_id] -> Ok(rating_id)
    _ -> Error(Nil)
  }
}

fn health_handler() -> Response {
  json_response(
    200,
    json.object([#("status", json.string("ok"))])
    |> json.to_string(),
  )
}

fn created(rating_with_user: shared.RatingWithUser) -> Response {
  let json_body = shared.rating_with_user_to_json(rating_with_user)
    |> json.to_string
  server.json_response(201, json_body)
}

fn not_found() -> Response {
  json_response(
    404,
    json.object([#("error", json.string("Not found"))])
    |> json.to_string(),
  )
}

fn unprocessable_entity(error: AppError) -> Response {
  let msg = shared.error_message(error)
  server.json_response(
    422,
    json.object([#("error", json.string(msg))])
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

fn static_index() -> Response {
  server.html_response(
    200,
    "<!DOCTYPE html><html><head><title>Boba Raider 8</title></head><body><h1>Boba Raider 8</h1></body></html>",
  )
}

fn static_file(path: String) -> Response {
  // Serve static files - simplified for now
  server.text_response(200, "Static file: " <> path)
}
