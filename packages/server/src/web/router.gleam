import gleam/json
import gleam/option.{None, Some}
import gleam/string
import shared.{type Todo}
import todo_store.{type Store}
import web/server.{type Request, type Response}
import web/static

pub fn make_handler(store: Store) -> fn(Request) -> Response {
  fn(request: Request) { route(request, store) }
}

fn route(request: Request, store: Store) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "GET", path -> {
      case string.starts_with(path, "/api/todos/") {
        True -> get_todo_handler(store, path)
        False -> route_get(path)
      }
    }
    _, _ -> not_found()
  }
}

fn route_get(path: String) -> Response {
  case string.starts_with(path, "/static/") {
    True -> static.serve(path)
    False -> not_found()
  }
}

fn get_todo_handler(store: Store, path: String) -> Response {
  // Extract ID from /api/todos/:id
  let id = case string.split(path, "/api/todos/") {
    [_, id] -> id
    _ -> ""
  }

  // Return 404 for empty or invalid ID formats
  case string.is_empty(id) {
    True -> todo_not_found()
    False -> {
      case todo_store.get_api(store, id) {
        todo_store.GetOkResult(item) -> {
          let json_body = todo_to_json(item)
          server.json_response(200, json_body)
        }
        todo_store.GetErrorResult(_) -> todo_not_found()
      }
    }
  }
}

fn todo_to_json(item: Todo) -> String {
  let description_value = case item.description {
    Some(d) -> json.string(d)
    None -> json.null()
  }

  // Convert timestamp to ISO 8601 string
  let created_at_str = timestamp_to_iso8601(item.created_at)

  json.object([
    #("id", json.string(item.id)),
    #("title", json.string(item.title)),
    #("description", description_value),
    #("priority", json.string(item.priority)),
    #("completed", json.bool(item.completed)),
    #("created_at", json.string(created_at_str)),
  ])
  |> json.to_string
}

// Convert millisecond timestamp to ISO 8601 format
fn timestamp_to_iso8601(timestamp_ms: Int) -> String {
  // Simple conversion - treat as UTC
  // Format: YYYY-MM-DDTHH:MM:SS.sssZ
  let seconds = timestamp_ms / 1000
  let milliseconds = timestamp_ms % 1000

  // Calculate date components (simplified)
  let days_since_epoch = seconds / 86400
  let seconds_in_day = seconds % 86400

  // Year calculation (approximate, accounting for leap years)
  let years_since_1970 = days_since_epoch / 365
  let year = 1970 + years_since_1970

  // Day of year
  let is_leap = year % 4 == 0 && { year % 100 != 0 || year % 400 == 0 }
  let _days_in_year = case is_leap {
    True -> 366
    False -> 365
  }
  let day_of_year = days_since_epoch % 365

  // Month calculation
  let month_days = case is_leap {
    True -> [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    False -> [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  }

  let #(month, day) = calculate_month_day(day_of_year, month_days, 1, 0)

  // Time components
  let hour = seconds_in_day / 3600
  let minute = { seconds_in_day % 3600 } / 60
  let second = seconds_in_day % 60

  // Format with zero padding
  pad4(year) <> "-" <> pad2(month) <> "-" <> pad2(day) <> "T" <> pad2(hour) <> ":" <> pad2(minute) <> ":" <> pad2(second) <> "." <> pad3(milliseconds) <> "Z"
}

fn calculate_month_day(day_of_year: Int, month_days: List(Int), month: Int, accumulated: Int) -> #(Int, Int) {
  case month_days {
    [] -> #(1, 1)  // Should not happen
    [days, ..rest] -> {
      let next_accumulated = accumulated + days
      case day_of_year < next_accumulated {
        True -> #(month, day_of_year - accumulated + 1)
        False -> calculate_month_day(day_of_year, rest, month + 1, next_accumulated)
      }
    }
  }
}

fn pad2(n: Int) -> String {
  let s = int_to_string(n)
  case string.length(s) {
    1 -> "0" <> s
    _ -> s
  }
}

fn pad3(n: Int) -> String {
  let s = int_to_string(n)
  case string.length(s) {
    1 -> "00" <> s
    2 -> "0" <> s
    _ -> s
  }
}

fn pad4(n: Int) -> String {
  let s = int_to_string(n)
  case string.length(s) {
    1 -> "000" <> s
    2 -> "00" <> s
    3 -> "0" <> s
    _ -> s
  }
}

fn int_to_string(n: Int) -> String {
  case n {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    6 -> "6"
    7 -> "7"
    8 -> "8"
    9 -> "9"
    _ -> int_to_string(n / 10) <> int_to_string(n % 10)
  }
}

fn todo_not_found() -> Response {
  server.json_response(
    404,
    json.object([#("error", json.string("Todo not found"))])
    |> json.to_string,
  )
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
