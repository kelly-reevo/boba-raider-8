/// Boba Validation - Shared validation types and functions
/// Used for input validation across client and server

import gleam/option.{type Option}
import gleam/string

/// Input for creating a new store
pub type StoreInput {
  StoreInput(
    name: String,
    address: Option(String),
    city: Option(String),
    phone: Option(String),
  )
}

/// Input for creating a new drink
pub type DrinkInput {
  DrinkInput(
    name: String,
    store_id: Int,
  )
}

/// Validate store input
/// Returns Ok(Nil) if valid, Error(String) if invalid
pub fn validate_store_input(input: StoreInput) -> Result(Nil, String) {
  let name_trimmed = string.trim(input.name)
  case string.length(name_trimmed) {
    0 -> Error("Store name is required")
    n if n > 100 -> Error("Store name must be at most 100 characters")
    _ -> Ok(Nil)
  }
}

/// Validate drink input
/// Returns Ok(Nil) if valid, Error(String) if invalid
pub fn validate_drink_input(input: DrinkInput) -> Result(Nil, String) {
  let name_trimmed = string.trim(input.name)
  case string.length(name_trimmed) {
    0 -> Error("Drink name is required")
    n if n > 100 -> Error("Drink name must be at most 100 characters")
    _ -> Ok(Nil)
  }
}
