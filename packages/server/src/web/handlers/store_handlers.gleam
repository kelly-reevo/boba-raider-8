/// HTTP handlers for store-related endpoints

import gleam/int
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/string
import shared.{type AppError, InvalidInput, NotFound}
import web/server.{type Request, type Response, json_response}
import web/store.{type Drink, type PaginationMeta, type Rating}

// ============== Query Parameter Parsing ==============

fn parse_int_param(value: Option(String), default: Int) -> Int {
  case value {
    None -> default
    Some(s) -> case int.parse(s) {
      Ok(n) if n > 0 -> n
      _ -> default
    }
  }
}

fn get_query_param(params: List(#(String, String)), key: String) -> Option(String) {
  case list_find(params, fn(p) { p.0 == key }) {
    Ok(#(_, value)) -> Some(value)
    Error(_) -> None
  }
}

fn list_find(list: List(a), predicate: fn(a) -> Bool) -> Result(a, Nil) {
  case list {
    [] -> Error(Nil)
    [head, ..tail] -> case predicate(head) {
      True -> Ok(head)
      False -> list_find(tail, predicate)
    }
  }
}

// ============== Path Extraction ==============

fn extract_store_id_from_path(path: String) -> Option(String) {
  // Path format: /api/stores/:store_id/drinks
  let parts = string.split(path, "/")
  case parts {
    ["", "api", "stores", store_id, "drinks"] -> Some(store_id)
    ["api", "stores", store_id, "drinks"] -> Some(store_id)
    _ -> None
  }
}

// ============== JSON Serialization ==============

fn drink_to_json(drink: Drink) -> json.Json {
  json.object([
    #("id", json.string(drink.id)),
    #("name", json.string(drink.name)),
    #("tea_type", json.string(store.tea_type_to_string(drink.tea_type))),
    #("price", case drink.price {
      Some(p) -> json.float(p)
      None -> json.null()
    }),
    #("image_url", case drink.image_url {
      Some(url) -> json.string(url)
      None -> json.null()
    }),
    #("average_rating", rating_to_json(drink.average_rating)),
  ])
}

fn rating_to_json(rating: Option(Rating)) -> json.Json {
  case rating {
    None -> json.object([
      #("overall", json.null()),
      #("sweetness", json.null()),
      #("texture", json.null()),
      #("tea_strength", json.null()),
    ])
    Some(r) -> json.object([
      #("overall", json.float(r.overall)),
      #("sweetness", json.float(r.sweetness)),
      #("texture", json.float(r.texture)),
      #("tea_strength", json.float(r.tea_strength)),
    ])
  }
}

fn meta_to_json(meta: PaginationMeta) -> json.Json {
  json.object([
    #("total", json.int(meta.total)),
    #("page", json.int(meta.page)),
    #("limit", json.int(meta.limit)),
    #("total_pages", json.int(meta.total_pages)),
  ])
}

// ============== Error Responses ==============

fn error_to_response(error: AppError) -> Response {
  case error {
    NotFound(msg) -> {
      json_response(
        404,
        json.object([
          #("error", json.string("store not found")),
          #("message", json.string(msg)),
        ])
        |> json.to_string,
      )
    }
    InvalidInput(msg) -> {
      json_response(
        400,
        json.object([
          #("error", json.string("invalid_input")),
          #("message", json.string(msg)),
        ])
        |> json.to_string,
      )
    }
    _ -> {
      json_response(
        500,
        json.object([
          #("error", json.string("internal_error")),
          #("message", json.string("An unexpected error occurred")),
        ])
        |> json.to_string,
      )
    }
  }
}

// ============== Handlers ==============

pub fn list_drinks_handler(request: Request) -> Response {
  let query_params = parse_query_string(request.path)

  case extract_store_id_from_path(request.path) {
    None -> not_found_response()
    Some(store_id) -> {
      // Parse query parameters
      let tea_type_filter = case get_query_param(query_params, "tea_type") {
        None -> None
        Some(tea_type_str) -> {
          case store.tea_type_from_string(tea_type_str) {
            Ok(tt) -> Some(tt)
            Error(_) -> None // Invalid tea_type is ignored (no filter)
          }
        }
      }

      let sort = case get_query_param(query_params, "sort") {
        None -> store.default_sort()
        Some(sort_str) -> {
          case store.sort_option_from_string(sort_str) {
            Ok(s) -> s
            Error(_) -> store.default_sort()
          }
        }
      }

      let page = parse_int_param(get_query_param(query_params, "page"), 1)
      let limit = parse_int_param(get_query_param(query_params, "limit"), 20)
      let limit = case limit {
        n if n > 100 -> 100 // Cap at 100
        n -> n
      }

      // Call data layer
      case store.list_drinks(store_id, tea_type_filter, sort, page, limit) {
        Error(error) -> error_to_response(error)
        Ok(#(drinks, meta)) -> {
          let body = json.object([
            #("data", json.array(drinks, drink_to_json)),
            #("meta", meta_to_json(meta)),
          ])
          json_response(200, json.to_string(body))
        }
      }
    }
  }
}

fn parse_query_string(path: String) -> List(#(String, String)) {
  case string.split(path, "?") {
    [_, query] -> {
      string.split(query, "&")
      |> list_filter_map(fn(part) {
        case string.split(part, "=") {
          [key, value] -> Ok(#(key, value))
          _ -> Error(Nil)
        }
      })
    }
    _ -> []
  }
}

fn list_filter_map(list: List(a), f: fn(a) -> Result(b, Nil)) -> List(b) {
  case list {
    [] -> []
    [head, ..tail] -> {
      case f(head) {
        Ok(b) -> [b, ..list_filter_map(tail, f)]
        Error(_) -> list_filter_map(tail, f)
      }
    }
  }
}

fn not_found_response() -> Response {
  json_response(
    404,
    json.object([#("error", json.string("Not found"))])
    |> json.to_string,
  )
}
