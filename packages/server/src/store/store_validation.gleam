import gleam/option.{type Option}
import gleam/string

/// Validation error for store operations
pub type StoreValidationError {
  StoreNameRequired
  StoreNameTooLong(max_length: Int)
  StoreNotFound(store_id: String)
  InvalidStoreIdFormat
  SearchTermRequired
  SearchTermTooShort(min_length: Int)
}

/// Input for creating a new store
pub type CreateStoreInput {
  CreateStoreInput(
    name: String,
    address: Option(String),
    city: Option(String),
    phone: Option(String),
  )
}

/// Result type for validation
pub type ValidationResult {
  ValidationSuccess
  ValidationError(String)
}

/// Validate create store input
pub fn validate_create_input(input: CreateStoreInput) -> Result(Nil, String) {
  let trimmed_name = string.trim(input.name)

  case string.length(trimmed_name) {
    0 -> Error("Store name is required")
    n if n > 100 -> Error("Store name exceeds maximum length of 100 characters")
    _ -> Ok(Nil)
  }
}

/// Validate search term
pub fn validate_search_term(term: String) -> Result(String, String) {
  let trimmed = string.trim(term)

  case string.length(trimmed) {
    0 -> Error("Search term is required")
    n if n < 2 -> Error("Search term must be at least 2 characters")
    _ -> Ok(trimmed)
  }
}

/// Validate store ID format (basic UUID validation)
pub fn validate_store_id(id: String) -> Result(String, String) {
  // Basic check: must be non-empty and have the right structure (contains dashes for UUID format)
  case string.length(id) > 0 && string.contains(id, "-") {
    False -> Error("Invalid store ID format")
    True -> Ok(id)
  }
}

/// Format validation error to string
pub fn format_error(error: StoreValidationError) -> String {
  case error {
    StoreNameRequired -> "Store name is required"
    StoreNameTooLong(max) -> "Store name exceeds maximum length of " <> int_to_string(max) <> " characters"
    StoreNotFound(id) -> "Store not found: " <> id
    InvalidStoreIdFormat -> "Invalid store ID format"
    SearchTermRequired -> "Search term is required"
    SearchTermTooShort(min) -> "Search term must be at least " <> int_to_string(min) <> " characters"
  }
}

fn int_to_string(n: Int) -> String {
  case n {
    0 -> "0"
    _ -> do_int_to_string(n, "")
  }
}

fn do_int_to_string(n: Int, acc: String) -> String {
  case n {
    0 -> acc
    _ -> {
      let digit = case n % 10 {
        0 -> "0"
        1 -> "1"
        2 -> "2"
        3 -> "3"
        4 -> "4"
        5 -> "5"
        6 -> "6"
        7 -> "7"
        8 -> "8"
        _ -> "9"
      }
      do_int_to_string(n / 10, digit <> acc)
    }
  }
}
