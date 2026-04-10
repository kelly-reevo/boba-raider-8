/// Drink model - domain types and pure functions

import gleam/float
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

/// Tea type enumeration
pub type TeaType {
  Black
  Green
  Oolong
  White
  Herbal
  Milk
  Fruit
  Other
}

/// Parse tea type from string
pub fn parse_tea_type(s: String) -> Result(TeaType, String) {
  case string.lowercase(s) {
    "black" -> Ok(Black)
    "green" -> Ok(Green)
    "oolong" -> Ok(Oolong)
    "white" -> Ok(White)
    "herbal" -> Ok(Herbal)
    "milk" -> Ok(Milk)
    "fruit" -> Ok(Fruit)
    "other" -> Ok(Other)
    _ -> Error("Invalid tea_type: " <> s)
  }
}

/// Convert tea type to string
pub fn tea_type_to_string(t: TeaType) -> String {
  case t {
    Black -> "black"
    Green -> "green"
    Oolong -> "oolong"
    White -> "white"
    Herbal -> "herbal"
    Milk -> "milk"
    Fruit -> "fruit"
    Other -> "other"
  }
}

/// User role for authorization
pub type UserRole {
  Regular
  StoreCreator
  Admin
}

/// User info for authorization checks
pub type User {
  User(id: String, role: UserRole, store_id: Option(String))
}

/// Drink entity
pub type Drink {
  Drink(
    id: String,
    store_id: String,
    creator_id: String,
    name: String,
    tea_type: TeaType,
    price: Float,
    description: String,
    image_url: Option(String),
    is_signature: Bool,
  )
}

/// Update request fields - all optional
pub type DrinkUpdate {
  DrinkUpdate(
    name: Option(String),
    tea_type: Option(TeaType),
    price: Option(Float),
    description: Option(String),
    image_url: Option(String),
    is_signature: Option(Bool),
  )
}

/// Empty update - no fields to change
pub fn empty_update() -> DrinkUpdate {
  DrinkUpdate(
    name: None,
    tea_type: None,
    price: None,
    description: None,
    image_url: None,
    is_signature: None,
  )
}

/// Check if user can modify a drink
/// Rules: creator of drink, store creator for that store, or admin
pub fn can_modify(user: User, drink: Drink) -> Bool {
  case user.role {
    Admin -> True
    _ -> {
      // User is the drink creator
      user.id == drink.creator_id
      || {
        // User is the store creator for this drink's store
        case user.store_id {
          Some(sid) -> sid == drink.store_id && user.role == StoreCreator
          None -> False
        }
      }
    }
  }
}

/// Apply update to drink - pure function, returns new drink
pub fn apply_update(drink: Drink, update: DrinkUpdate) -> Drink {
  Drink(
    ..drink,
    name: option.unwrap(update.name, drink.name),
    tea_type: option.unwrap(update.tea_type, drink.tea_type),
    price: option.unwrap(update.price, drink.price),
    description: option.unwrap(update.description, drink.description),
    image_url: option.or(update.image_url, drink.image_url),
    is_signature: option.unwrap(update.is_signature, drink.is_signature),
  )
}

/// Validate name: non-empty, max 100 chars
pub fn validate_name(name: String) -> Result(String, String) {
  let trimmed = string.trim(name)
  case string.length(trimmed) {
    0 -> Error("Name cannot be empty")
    n if n > 100 -> Error("Name too long (max 100 characters)")
    _ -> Ok(trimmed)
  }
}

/// Validate price: positive number
pub fn validate_price(price: Float) -> Result(Float, String) {
  case price >. 0.0 {
    True -> Ok(price)
    False -> Error("Price must be positive")
  }
}

/// Validate description: max 500 chars
pub fn validate_description(desc: String) -> Result(String, String) {
  case string.length(desc) {
    n if n > 500 -> Error("Description too long (max 500 characters)")
    _ -> Ok(desc)
  }
}

/// Validate image_url: must be valid URL format (basic check)
pub fn validate_image_url(url: String) -> Result(String, String) {
  let trimmed = string.trim(url)
  case string.starts_with(trimmed, "http://")
    || string.starts_with(trimmed, "https://")
  {
    True -> Ok(trimmed)
    False -> Error("Image URL must start with http:// or https://")
  }
}

/// Build validated update from raw fields
/// Returns error if any field fails validation
pub fn build_update(
  name: Option(String),
  tea_type: Option(TeaType),
  price: Option(Float),
  description: Option(String),
  image_url: Option(String),
  is_signature: Option(Bool),
) -> Result(DrinkUpdate, String) {
  // Validate name if provided
  use validated_name <- result.try(case name {
    Some(n) -> {
      case validate_name(n) {
        Ok(valid) -> Ok(Some(valid))
        Error(e) -> Error(e)
      }
    }
    None -> Ok(None)
  })

  // Validate price if provided
  use validated_price <- result.try(case price {
    Some(p) -> {
      case validate_price(p) {
        Ok(valid) -> Ok(Some(valid))
        Error(e) -> Error(e)
      }
    }
    None -> Ok(None)
  })

  // Validate description if provided
  use validated_desc <- result.try(case description {
    Some(d) -> {
      case validate_description(d) {
        Ok(valid) -> Ok(Some(valid))
        Error(e) -> Error(e)
      }
    }
    None -> Ok(None)
  })

  // Validate image_url if provided
  use validated_url <- result.try(case image_url {
    Some("") -> Ok(None)
    Some(url) -> {
      case validate_image_url(url) {
        Ok(valid) -> Ok(Some(valid))
        Error(e) -> Error(e)
      }
    }
    None -> Ok(None)
  })

  Ok(
    DrinkUpdate(
      name: validated_name,
      tea_type: tea_type,
      price: validated_price,
      description: validated_desc,
      image_url: validated_url,
      is_signature: is_signature,
    ),
  )
}

/// Convert drink to JSON
pub fn to_json(drink: Drink) -> String {
  let image_json = case drink.image_url {
    Some(url) -> "\"" <> url <> "\""
    None -> "null"
  }

  "{\"id\":\"" <> drink.id <> "\","
  <> "\"store_id\":\"" <> drink.store_id <> "\","
  <> "\"creator_id\":\"" <> drink.creator_id <> "\","
  <> "\"name\":\"" <> drink.name <> "\","
  <> "\"tea_type\":\"" <> tea_type_to_string(drink.tea_type) <> "\","
  <> "\"price\":" <> float.to_string(drink.price) <> ","
  <> "\"description\":\"" <> drink.description <> "\","
  <> "\"image_url\":" <> image_json <> ","
  <> "\"is_signature\":" <> case drink.is_signature {
    True -> "true"
    False -> "false"
  } <> "}"
}
