/// Store List Handler - GET /api/stores endpoint
/// Handles listing stores with pagination, search, and sorting

import boba_types.{type SimpleStoreListResponse, StoreListItem, SimpleStoreListResponse, simple_store_list_response_to_json}
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/string
import store/store_data_access as store_access
import web/server.{type Request, type Response, json_response}

/// Default pagination values
const default_limit = 20

const default_offset = 0

const max_limit = 100

/// Handle GET /api/stores request
pub fn handle_list_stores(request: Request) -> Response {
  // Parse query parameters from the path
  let params = parse_query_params(request.path)

  // Get stores from data access layer
  let store_state = store_access.new_state()
  let paginated = store_access.list_with_params(store_state, params)

  // Convert to API response format
  let response = convert_to_response(paginated)

  json_response(
    200,
    simple_store_list_response_to_json(response)
    |> json.to_string,
  )
}

/// Parse query parameters from request path
type ListParams {
  ListParams(
    limit: Int,
    offset: Int,
    search: Option(String),
    sort_by: store_access.SortBy,
    sort_order: store_access.SortOrder,
  )
}

fn parse_query_params(path: String) -> store_access.ListStoresInput {
  // Extract query string from path (after ?)
  let query_string = case string.split(path, "?") {
    [_, query] -> query
    _ -> ""
  }

  let limit = parse_int_param(query_string, "limit", default_limit)
  let limit = case limit > max_limit {
    True -> max_limit
    False -> limit
  }
  let limit = case limit <= 0 {
    True -> default_limit
    False -> limit
  }

  let offset = parse_int_param(query_string, "offset", default_offset)
  let offset = case offset < 0 {
    True -> 0
    False -> offset
  }

  let search = parse_string_param(query_string, "search")
  let search = case search {
    Some(s) -> {
      let trimmed = string.trim(s)
      case string.is_empty(trimmed) {
        True -> None
        False -> Some(trimmed)
      }
    }
    None -> None
  }

  let sort_by = parse_sort_by(query_string)
  let sort_order = parse_sort_order(query_string)

  store_access.ListStoresInput(
    limit: limit,
    offset: offset,
    search: search,
    sort_by: sort_by,
    sort_order: sort_order,
  )
}

/// Parse integer parameter from query string
fn parse_int_param(query: String, key: String, default: Int) -> Int {
  case extract_param(query, key) {
    Some(value) -> {
      case int.parse(value) {
        Ok(n) -> n
        Error(_) -> default
      }
    }
    None -> default
  }
}

/// Parse string parameter from query string
fn parse_string_param(query: String, key: String) -> Option(String) {
  case extract_param(query, key) {
    Some(value) -> Some(value)
    None -> None
  }
}

/// Parse sort_by parameter
fn parse_sort_by(query: String) -> store_access.SortBy {
  case extract_param(query, "sort_by") {
    Some("city") -> store_access.SortByCity
    Some("created_at") -> store_access.SortByCreatedAt
    Some("name") | _ -> store_access.SortByName
  }
}

/// Parse sort_order parameter
fn parse_sort_order(query: String) -> store_access.SortOrder {
  case extract_param(query, "sort_order") {
    Some("desc") -> store_access.Desc
    Some("asc") | _ -> store_access.Asc
  }
}

/// Extract parameter value from query string
/// Simple implementation - assumes well-formed query string
fn extract_param(query: String, key: String) -> Option(String) {
  let pairs = string.split(query, "&")
  list.find_map(pairs, fn(pair) {
    case string.split(pair, "=") {
      [k, v] -> {
        case k == key {
          True -> Ok(Some(url_decode(v)))
          False -> Error(Nil)
        }
      }
      _ -> Error(Nil)
    }
  })
  |> fn(result) {
    case result {
      Ok(Some(v)) -> Some(v)
      _ -> None
    }
  }
}

/// Simple URL decode - handles %20 as space
fn url_decode(value: String) -> String {
  // Replace %20 with space (basic URL decoding)
  let decoded = string.replace(value, "%20", " ")
  // Replace + with space
  let decoded = string.replace(decoded, "+", " ")
  decoded
}

/// Convert paginated stores to API response
fn convert_to_response(
  paginated: store_access.PaginatedStores,
) -> SimpleStoreListResponse {
  let items = list.map(paginated.stores, fn(store) {
    StoreListItem(
      id: store.id,
      name: store.name,
      city: option.unwrap(store.city, ""),
      drink_count: 0,
    )
  })

  SimpleStoreListResponse(
    stores: items,
    total: paginated.total,
  )
}
