/// Shared types and functions for boba-raider-8

import gleam/option.{type Option}

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

// Store types

pub type StoreSummary {
  StoreSummary(
    id: String,
    name: String,
    address: String,
    image_url: Option(String),
  )
}

// Rating types

pub type RatingWithStore {
  RatingWithStore(
    id: String,
    overall_score: Float,
    review_text: Option(String),
    created_at: String,
    updated_at: String,
    store: StoreSummary,
  )
}

// Pagination types

pub type PaginationMeta {
  PaginationMeta(
    total: Int,
    page: Int,
    limit: Int,
    total_pages: Int,
  )
}

pub type PaginatedResponse(a) {
  PaginatedResponse(
    data: List(a),
    meta: PaginationMeta,
  )
}
