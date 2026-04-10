/// Shared types and functions for boba-raider-8

import gleam/dynamic/decode
import gleam/json

pub type AppError {
  NotFound(String)
  InvalidInput(String)
  InternalError(String)
}

/// Convert an error to a human-readable message
pub fn error_message(error: AppError) -> String {
  case error {
    NotFound(msg) -> "Not found: " <> msg
    InvalidInput(msg) -> "Invalid input: " <> msg
    InternalError(msg) -> "Internal error: " <> msg
  }
}

/// Store domain model
pub type Store {
  Store(
    id: String,
    name: String,
    address: String,
    image_url: String,
    average_rating: Float,
    total_reviews: Int,
  )
}

/// Sort options for store listing
pub type SortOption {
  RatingDesc
  RatingAsc
  NameAsc
  NameDesc
  MostReviewed
}

/// Convert SortOption to query string value
pub fn sort_to_string(sort: SortOption) -> String {
  case sort {
    RatingDesc -> "rating_desc"
    RatingAsc -> "rating_asc"
    NameAsc -> "name_asc"
    NameDesc -> "name_desc"
    MostReviewed -> "most_reviewed"
  }
}

/// Parse SortOption from string
pub fn sort_from_string(s: String) -> SortOption {
  case s {
    "rating_desc" -> RatingDesc
    "rating_asc" -> RatingAsc
    "name_desc" -> NameDesc
    "most_reviewed" -> MostReviewed
    _ -> NameAsc
  }
}

/// Store list filters
pub type StoreFilters {
  StoreFilters(
    query: String,
    location: String,
    sort: SortOption,
    page: Int,
  )
}

/// Paginated store response
pub type StoreListResponse {
  StoreListResponse(
    stores: List(Store),
    total: Int,
    page: Int,
    per_page: Int,
  )
}

/// JSON decoder for Store
fn store_decoder() -> decode.Decoder(Store) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use address <- decode.field("address", decode.string)
  use image_url <- decode.field("image_url", decode.string)
  use average_rating <- decode.field("average_rating", decode.float)
  use total_reviews <- decode.field("total_reviews", decode.int)
  decode.success(Store(id:, name:, address:, image_url:, average_rating:, total_reviews:))
}

/// Parse store list from JSON
pub fn decode_store_list(json_string: String) -> Result(List(Store), AppError) {
  let store_list_decoder = {
    use stores <- decode.field("stores", decode.list(of: store_decoder()))
    decode.success(stores)
  }

  case json.parse(json_string, store_list_decoder) {
    Ok(stores) -> Ok(stores)
    Error(_) -> Error(InvalidInput("Failed to decode store list"))
  }
}

/// Default empty filters
pub fn default_filters() -> StoreFilters {
  StoreFilters(
    query: "",
    location: "",
    sort: RatingDesc,
    page: 1,
  )
}
