import web/auth
import data/ratings
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import shared.{
  type PaginatedResponse, type PaginationMeta, type RatingWithStore,
  type StoreSummary,
}
import web/server.{type Request, type Response, json_response}

/// Handle GET /api/users/me/ratings/stores?page={n}&limit={n}
pub fn list_user_ratings(request: Request) -> Response {
  // 1. Extract user_id from auth header (401 if missing)
  case auth.require_user(request) {
    Ok(user_id) -> {
      // 2. Parse page/limit from query params
      let #(page, limit) = parse_pagination_params(request.path)

      // 3. Get ratings from database
      let db = ratings.get_db()
      case ratings.list_user_ratings_with_stores(db, user_id, page, limit) {
        Ok(response) -> encode_response(response)
        Error(error) -> handle_error(error)
      }
    }
    Error(response) -> response
  }
}

fn parse_pagination_params(path: String) -> #(Int, Int) {
  let page = parse_query_int(path, "page", 1)
  let limit = parse_query_int(path, "limit", 20)
  // Clamp limit to reasonable range
  let clamped_limit = int.clamp(limit, 1, 100)
  #(page, clamped_limit)
}

fn parse_query_int(path: String, param: String, default: Int) -> Int {
  case string.split(path, "?") {
    [_, query_string] -> {
      let pairs = string.split(query_string, "&")
      list.fold(pairs, default, fn(acc, pair) {
        case string.split(pair, "=") {
          [key, value] if key == param ->
            case int.parse(value) {
              Ok(n) if n > 0 -> n
              _ -> acc
            }
          _ -> acc
        }
      })
    }
    _ -> default
  }
}

fn encode_response(response: PaginatedResponse(RatingWithStore)) -> Response {
  let data_json = json.array(response.data, encode_rating_with_store)
  let meta_json = encode_pagination_meta(response.meta)

  let body =
    json.object([
      #("data", data_json),
      #("meta", meta_json),
    ])
    |> json.to_string

  json_response(200, body)
}

fn encode_rating_with_store(rating: RatingWithStore) -> json.Json {
  json.object([
    #("id", json.string(rating.id)),
    #("overall_score", json.float(rating.overall_score)),
    #(
      "review_text",
      case rating.review_text {
        Some(text) -> json.string(text)
        None -> json.null()
      },
    ),
    #("created_at", json.string(rating.created_at)),
    #("updated_at", json.string(rating.updated_at)),
    #("store", encode_store_summary(rating.store)),
  ])
}

fn encode_store_summary(store: StoreSummary) -> json.Json {
  json.object([
    #("id", json.string(store.id)),
    #("name", json.string(store.name)),
    #("address", json.string(store.address)),
    #(
      "image_url",
      case store.image_url {
        Some(url) -> json.string(url)
        None -> json.null()
      },
    ),
  ])
}

fn encode_pagination_meta(meta: PaginationMeta) -> json.Json {
  json.object([
    #("total", json.int(meta.total)),
    #("page", json.int(meta.page)),
    #("limit", json.int(meta.limit)),
    #("total_pages", json.int(meta.total_pages)),
  ])
}

fn handle_error(error: shared.AppError) -> Response {
  let message = shared.error_message(error)
  let code = case error {
    shared.NotFound(_) -> 404
    shared.InvalidInput(_) -> 400
    shared.InternalError(_) -> 500
  }

  let body =
    json.object([#("error", json.string(message))])
    |> json.to_string

  json_response(code, body)
}
