/// Drink input validation module
/// Validates drink data before persistence

import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

/// Input type for drink validation
pub type Drink {
  Drink(
    store_id: Option(String),
    name: String,
    base_tea_type: Option(String),
    price: Option(Float),
  )
}

/// Validation error with field name and message
pub type ValidationError {
  ValidationError(field: String, message: String)
}

/// Result of successful validation
pub type ValidationResult {
  Valid
}

/// Valid base tea types
const valid_tea_types = ["black", "green", "oolong", "white", "milk"]

/// Validate a drink input
/// Returns Ok(Valid) if all validations pass, or Error with list of validation errors
pub fn validate(drink: Drink) -> Result(ValidationResult, List(ValidationError)) {
  let errors = list.flatten([
    validate_name(drink.name),
    validate_store_id(drink.store_id),
    validate_base_tea_type(drink.base_tea_type),
    validate_price(drink.price),
  ])

  case errors {
    [] -> Ok(Valid)
    _ -> Error(errors)
  }
}

fn validate_name(name: String) -> List(ValidationError) {
  case string.trim(name) {
    "" -> [ValidationError(field: "name", message: "name is required")]
    trimmed -> {
      let length = string.length(trimmed)
      case length >= 2 && length <= 255 {
        True -> []
        False -> [
          ValidationError(
            field: "name",
            message: "name must be between 2 and 255 characters",
          ),
        ]
      }
    }
  }
}

fn validate_store_id(store_id: Option(String)) -> List(ValidationError) {
  case store_id {
    None -> [ValidationError(field: "store_id", message: "store_id is required")]
    Some("") -> [
      ValidationError(field: "store_id", message: "store_id is required"),
    ]
    Some(_) -> []
  }
}

fn validate_base_tea_type(tea_type: Option(String)) -> List(ValidationError) {
  case tea_type {
    None -> []
    Some(t) -> {
      case list.contains(valid_tea_types, t) {
        True -> []
        False -> [
          ValidationError(
            field: "base_tea_type",
            message: "base_tea_type must be one of: black, green, oolong, white, milk",
          ),
        ]
      }
    }
  }
}

fn validate_price(price: Option(Float)) -> List(ValidationError) {
  case price {
    None -> []
    Some(p) -> {
      case p >. 0.0 {
        True -> []
        False -> [
          ValidationError(field: "price", message: "price must be positive"),
        ]
      }
    }
  }
}
