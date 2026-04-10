/// Shared types and functions for boba-raider-8

import gleam/dynamic/decode
import gleam/json

pub type AppError {
  NotFound(String)
  InvalidInput(String)
  Unauthorized(String)
  InternalError(String)
  Unauthorized(String)
}

/// Convert an error to a human-readable message
pub fn error_message(error: AppError) -> String {
  case error {
    NotFound(msg) -> "Not found: " <> msg
    InvalidInput(msg) -> "Invalid input: " <> msg
    Unauthorized(msg) -> "Unauthorized: " <> msg
    InternalError(msg) -> "Internal error: " <> msg
    Unauthorized(msg) -> "Unauthorized: " <> msg
  }
}

/// Tea types available for drinks
pub type TeaType {
  Black
  Green
  Oolong
  White
  Herbal
  Matcha
}

/// Convert TeaType to display string
pub fn tea_type_to_string(tea_type: TeaType) -> String {
  case tea_type {
    Black -> "Black"
    Green -> "Green"
    Oolong -> "Oolong"
    White -> "White"
    Herbal -> "Herbal"
    Matcha -> "Matcha"
  }
}

/// Get all available tea types
pub fn all_tea_types() -> List(TeaType) {
  [Black, Green, Oolong, White, Herbal, Matcha]
}

/// Parse tea type from string
pub fn parse_tea_type(s: String) -> Result(TeaType, String) {
  case s {
    "Black" -> Ok(Black)
    "Green" -> Ok(Green)
    "Oolong" -> Ok(Oolong)
    "White" -> Ok(White)
    "Herbal" -> Ok(Herbal)
    "Matcha" -> Ok(Matcha)
    _ -> Error("Invalid tea type: " <> s)
  }
}

/// Drink representation
pub type Drink {
  Drink(
    id: String,
    store_id: String,
    name: String,
    tea_type: TeaType,
    price: Float,
    description: String,
    image_url: String,
    is_signature: Bool,
  )
}

/// Input for creating a new drink
pub type CreateDrinkInput {
  CreateDrinkInput(
    name: String,
    tea_type: TeaType,
    price: Float,
    description: String,
    image_url: String,
    is_signature: Bool,
  )
}
