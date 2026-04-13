/// Create Drink Form - State and types for drink creation form

import gleam/float
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

/// Valid tea type enum values
pub type BaseTeaType {
  Black
  Green
  Oolong
  White
  Milk
}

/// Convert tea type to its string representation
pub fn tea_type_to_string(tea_type: BaseTeaType) -> String {
  case tea_type {
    Black -> "Black"
    Green -> "Green"
    Oolong -> "Oolong"
    White -> "White"
    Milk -> "Milk"
  }
}

/// All available tea types for dropdown
pub fn all_tea_types() -> List(BaseTeaType) {
  [Black, Green, Oolong, White, Milk]
}

/// Form field validation errors
pub type FieldError {
  NameRequired
  PriceInvalid
  StoreIdRequired
}

/// Current form state - using different names to avoid shadowing Result constructors
pub type FormState {
  Idle
  Submitting
  Succeeded(String)
  Failed(String)
}

/// Complete form data
pub type CreateDrinkForm {
  CreateDrinkForm(
    store_id: String,
    name: String,
    description: String,
    base_tea_type: String,
    price: String,
    state: FormState,
    field_errors: List(FieldError),
  )
}

/// Create empty form
pub fn empty_form() -> CreateDrinkForm {
  CreateDrinkForm(
    store_id: "",
    name: "",
    description: "",
    base_tea_type: "",
    price: "",
    state: Idle,
    field_errors: [],
  )
}

/// Create form with specific store_id pre-filled
pub fn form_for_store(store_id: String) -> CreateDrinkForm {
  CreateDrinkForm(
    store_id: store_id,
    name: "",
    description: "",
    base_tea_type: "",
    price: "",
    state: Idle,
    field_errors: [],
  )
}

/// Validate price string - must be positive number
pub fn validate_price(price_str: String) -> Result(Float, FieldError) {
  case price_str {
    "" -> Error(PriceInvalid)
    _ -> {
      case float.parse(price_str) {
        Ok(price) if price >. 0.0 -> Ok(price)
        _ -> Error(PriceInvalid)
      }
    }
  }
}

/// Check if name is valid (non-empty after trim)
pub fn is_valid_name(name: String) -> Bool {
  name |> string.trim |> string.length > 0
}

/// Check if store_id is valid (non-empty)
pub fn is_valid_store_id(store_id: String) -> Bool {
  store_id != ""
}

/// Run full form validation, returns list of errors
pub fn validate_form(form: CreateDrinkForm) -> List(FieldError) {
  let name_error = case is_valid_name(form.name) {
    True -> []
    False -> [NameRequired]
  }

  let store_error = case is_valid_store_id(form.store_id) {
    True -> []
    False -> [StoreIdRequired]
  }

  let price_error = case form.price {
    "" -> []
    price_str -> case validate_price(price_str) {
      Ok(_) -> []
      Error(e) -> [e]
    }
  }

  list.flatten([name_error, store_error, price_error])
}

/// Check if form can be submitted
pub fn is_valid(form: CreateDrinkForm) -> Bool {
  is_valid_name(form.name) && is_valid_store_id(form.store_id)
}

/// Get price as float option
pub fn price_as_float(form: CreateDrinkForm) -> Option(Float) {
  case validate_price(form.price) {
    Ok(price) -> Some(price)
    Error(_) -> None
  }
}
