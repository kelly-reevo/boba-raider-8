import gleam/json
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import store/store_service.{type PaginatedStoresResponse, type StoreWithDrinkCount, ListStoresInput}
import store/store_data_access.{SortByName, SortByCity, SortByCreatedAt, Asc, Desc}
import web/server.{type Request, type Response}
import web/static

pub fn make_handler() -> fn(Request) -> Response {
  fn(request: Request) { route(request) }
}

// Public handle_request function used by tests
pub fn handle_request(request: Request) -> Response {
  route(request)
}

fn route(request: Request) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "GET", path -> route_get(path)
    _, _ -> not_found()
  }
}

fn route_get(path: String) -> Response {
  // Check for /api/stores endpoint with or without query string
  case string.starts_with(path, "/api/stores") {
    True -> {
      let query_string = case path {
        "/api/stores" -> ""
        _ -> {
          // Extract query string after "/api/stores?"
          case string.split(path, "?") {
            [_, qs] -> qs
            _ -> ""
          }
        }
      }
      list_stores_handler(query_string)
    }
    False -> case string.starts_with(path, "/static/") {
      True -> static.serve(path)
      False -> not_found()
    }
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

// Parse query string into key-value pairs
fn parse_query_string(query_string: String) -> List(#(String, String)) {
  case query_string {
    "" -> []
    qs -> {
      qs
      |> string.split("&")
      |> list.filter_map(fn(pair) {
        case string.split(pair, "=") {
          [key, value] -> Ok(#(key, value))
          _ -> Error(Nil)
        }
      })
    }
  }
}

// Get query param value by key
fn get_query_param(params: List(#(String, String)), key: String) -> Option(String) {
  case list.find(params, fn(pair) { pair.0 == key }) {
    Ok(#(_, value)) -> Some(value)
    Error(_) -> None
  }
}

// Parse integer param with default
fn parse_int_param(value: Option(String), default: Int) -> Int {
  case value {
    None -> default
    Some(s) -> {
      case int.parse(s) {
        Ok(n) -> n
        Error(_) -> default
      }
    }
  }
}

// Validate sort_by enum value
fn parse_sort_by(value: Option(String)) -> Result(store_data_access.SortBy, String) {
  case value {
    None -> Ok(SortByCreatedAt)
    Some("name") -> Ok(SortByName)
    Some("city") -> Ok(SortByCity)
    Some("created_at") -> Ok(SortByCreatedAt)
    Some(invalid) -> Error("Invalid sort_by value: " <> invalid)
  }
}

// Validate sort_order enum value
fn parse_sort_order(value: Option(String)) -> Result(store_data_access.SortOrder, String) {
  case value {
    None -> Ok(Asc)
    Some("asc") -> Ok(Asc)
    Some("desc") -> Ok(Desc)
    Some(invalid) -> Error("Invalid sort_order value: " <> invalid)
  }
}

// Handler for GET /api/stores
fn list_stores_handler(query_string: String) -> Response {
  let params = parse_query_string(query_string)
  list_stores_handler_with_params(params)
}

// Handler with query parameters (used by tests)
pub fn list_stores_handler_with_params(params: List(#(String, String))) -> Response {
  // Get or create store service
  case store_service.start() {
    Error(msg) -> {
      server.json_response(
        500,
        json.object([#("error", json.string(msg))])
        |> json.to_string,
      )
    }
    Ok(service) -> {
      // Parse parameters
      let limit = parse_int_param(get_query_param(params, "limit"), 10)
      let offset = parse_int_param(get_query_param(params, "offset"), 0)
      let search = get_query_param(params, "search")
      let sort_by_result = parse_sort_by(get_query_param(params, "sort_by"))
      let sort_order_result = parse_sort_order(get_query_param(params, "sort_order"))

      // Validate sort parameters
      case sort_by_result, sort_order_result {
        Error(msg), _ -> {
          server.json_response(
            400,
            json.object([#("error", json.string(msg))])
            |> json.to_string,
          )
        }
        _, Error(msg) -> {
          server.json_response(
            400,
            json.object([#("error", json.string(msg))])
            |> json.to_string,
          )
        }
        Ok(sort_by), Ok(sort_order) -> {
          // Build input
          let input = ListStoresInput(
            limit: limit,
            offset: offset,
            search: search,
            sort_by: sort_by,
            sort_order: sort_order,
          )

          // List stores
          case store_service.list_stores(service, input) {
            Error(msg) -> {
              server.json_response(
                500,
                json.object([#("error", json.string(msg))])
                |> json.to_string,
              )
            }
            Ok(result) -> {
              server.json_response(
                200,
                encode_stores_response(result)
                |> json.to_string,
              )
            }
          }
        }
      }
    }
  }
}

// Encode a single store to JSON
fn encode_store(store: StoreWithDrinkCount) -> json.Json {
  json.object([
    #("id", json.string(store.id)),
    #("name", json.string(store.name)),
    #("city", case store.city {
      Some(city) -> json.string(city)
      None -> json.null()
    }),
    #("drink_count", json.int(store.drink_count)),
  ])
}

// Encode paginated stores response to JSON
fn encode_stores_response(response: PaginatedStoresResponse) -> json.Json {
  let stores_json = list.map(response.stores, encode_store)
  json.object([
    #("stores", json.preprocessed_array(stores_json)),
    #("total", json.int(response.total)),
    #("limit", json.int(response.limit)),
    #("offset", json.int(response.offset)),
  ])
}
