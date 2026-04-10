/// Shared types and functions for boba-raider-8

import gleam/int
import gleam/string

pub type AppError {
  NotFound(String)
  InvalidInput(String)
  Unauthorized(String)
  InternalError(String)
  Forbidden(String)
}

/// Convert an error to a human-readable message
pub fn error_message(error: AppError) -> String {
  case error {
    NotFound(msg) -> "Not found: " <> msg
    InvalidInput(msg) -> "Invalid input: " <> msg
    Unauthorized(msg) -> "Unauthorized: " <> msg
    InternalError(msg) -> "Internal error: " <> msg
    Forbidden(msg) -> "Forbidden: " <> msg
  }
}

/// User information for ratings display
pub type User {
  User(id: String, username: String)
}

/// Drink rating with all four rating axes
pub type Rating {
  Rating(
    id: String,
    user: User,
    drink_id: String,
    overall_score: Int,
    sweetness: Int,
    boba_texture: Int,
    tea_strength: Int,
    review_text: String,
    created_at: String,
    updated_at: String,
  )
}

/// Paginated response wrapper
pub type PaginatedResponse(a) {
  PaginatedResponse(data: List(a), meta: PaginationMeta)
}

/// Pagination metadata
pub type PaginationMeta {
  PaginationMeta(total: Int, page: Int, limit: Int, total_pages: Int)
}

/// Parse and validate pagination parameters
pub fn parse_pagination(
  page_raw: String,
  limit_raw: String,
) -> Result(#(Int, Int), AppError) {
  let page =
    case string.trim(page_raw) {
      "" -> 1
      p ->
        case int.parse(p) {
          Ok(n) if n >= 1 -> n
          _ -> 1
        }
    }

  let limit =
    case string.trim(limit_raw) {
      "" -> 20
      l ->
        case int.parse(l) {
          Ok(n) if n >= 1 && n <= 100 -> n
          Ok(n) if n > 100 -> 100
          _ -> 20
        }
    }

  Ok(#(page, limit))
}

/// Calculate pagination metadata
pub fn calculate_meta(total: Int, page: Int, limit: Int) -> PaginationMeta {
  let total_pages = case total % limit {
    0 -> total / limit
    _ -> total / limit + 1
  }

  PaginationMeta(total: total, page: page, limit: limit, total_pages: total_pages)
}
