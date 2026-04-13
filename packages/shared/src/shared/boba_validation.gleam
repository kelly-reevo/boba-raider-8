import gleam/dict.{type Dict}
import gleam/option.{type Option}

/// Input type for store creation (matching test expectations)
pub type StoreInput {
  StoreInput(
    name: String,
    address: Dict(String, String),
    phone: Dict(String, String),
  )
}

/// Input type for drink creation
pub type DrinkInput {
  DrinkInput(
    store_id: Int,
    name: String,
    description: Option(String),
    base_tea_type: Option(String),
    price: Option(Float),
  )
}

/// Validation error type
pub type ValidationError {
  ValidationError(field: String, message: String)
}

/// Validation result type
pub type ValidationResult {
  Valid
  Invalid(List(ValidationError))
}
