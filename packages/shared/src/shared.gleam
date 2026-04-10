/// Shared types and functions for boba-raider-8

import gleam/option.{type Option}

pub type AppError {
  NotFound(String)
  InvalidInput(String)
  Unauthorized(String)
  InternalError(String)
  Conflict(String)
}

/// Convert an error to a human-readable message
pub fn error_message(error: AppError) -> String {
  case error {
    NotFound(msg) -> "Not found: " <> msg
    InvalidInput(msg) -> "Invalid input: " <> msg
    Unauthorized(msg) -> "Unauthorized: " <> msg
    InternalError(msg) -> "Internal error: " <> msg
    Conflict(msg) -> "Conflict: " <> msg
  }
}

/// Tea types for drinks
pub type TeaType {
  Black
  Green
  Oolong
  White
  Herbal
  Milk
  Other
}

pub fn tea_type_to_string(tea_type: TeaType) -> String {
  case tea_type {
    Black -> "black"
    Green -> "green"
    Oolong -> "oolong"
    White -> "white"
    Herbal -> "herbal"
    Milk -> "milk"
    Other -> "other"
  }
}

pub fn tea_type_from_string(str: String) -> Result(TeaType, String) {
  case str {
    "black" -> Ok(Black)
    "green" -> Ok(Green)
    "oolong" -> Ok(Oolong)
    "white" -> Ok(White)
    "herbal" -> Ok(Herbal)
    "milk" -> Ok(Milk)
    "other" -> Ok(Other)
    _ -> Error("Invalid tea type: " <> str)
  }
}

/// Average rating for a drink
pub type AverageRating {
  AverageRating(
    overall: Option(Float),
    sweetness: Option(Float),
    texture: Option(Float),
    tea_strength: Option(Float),
  )
}

/// Drink entity
pub type Drink {
  Drink(
    id: String,
    store_id: String,
    name: String,
    tea_type: TeaType,
    price: Option(Float),
    description: Option(String),
    image_url: Option(String),
    is_signature: Bool,
    created_at: String,
    average_rating: AverageRating,
  )
}

/// Input for creating a drink
pub type CreateDrinkInput {
  CreateDrinkInput(
    name: String,
    tea_type: TeaType,
    price: Option(Float),
    description: Option(String),
    image_url: Option(String),
    is_signature: Bool,
  )
}
